// ============================================================================
// tcu_controller.v
// TCU - Transmission Control Unit (cambio automatico escalonado).
//
// Cambio: 5 marchas a frente + N (neutro) + R (re).  Tudo parametrizavel.
//   Codificacao da marcha (target_gear/current_gear):
//     0 = N (neutro)    1..5 = marchas a frente    6 = R (re)
//
// Seletor / modo de conducao (drive_mode):
//   bits [1:0] : 0=P, 1=R, 2=N, 3=D   (so em D ha troca automatica)
//   bit  [2]   : sport (segura marchas mais alto)
//
// COMPORTAMENTOS DE CONFORTO (requisitos do projeto):
//   1) HISTERESE: limiar de SUBIR (up) > limiar de DESCER (dn) para a mesma
//      fronteira de marcha. O vao entre eles impede o "fica-trocando"
//      (gear hunting) quando a velocidade fica colada no ponto de troca.
//      Modelados como DUAS tabelas separadas (up_base / dn_base).
//   2) COMPENSACAO DE RAMPA: usa a inclinacao estimada (incline_est).
//      Aclive  => atrasa subidas e adianta descidas (segura torque).
//      Declive => bloqueia subidas e segura marcha baixa (freio-motor).
//   3) TROCA CONFORTAVEL: dwell timer (tempo minimo na marcha antes de nova
//      troca) + lock de troca-em-andamento + corte momentaneo de torque
//      (torque_cut) que a ignicao/injecao usam para reduzir torque no engate.
//
// Os tempos (DWELL/CUT/ENGAGE/RESTORE) sao contados em CICLOS DE CLOCK.
// Com clock de 100 MHz (10 ns) os valores aqui sao escalados p/ simulacao;
// num ECU real escalam para centenas de ms ajustando os parametros.
// ============================================================================
module tcu_controller #(
    parameter integer        N_FWD         = 5,        // marchas a frente
    parameter [15:0]         DWELL_MIN     = 16'd200,  // tempo minimo na marcha
    parameter [15:0]         T_CUT         = 16'd20,   // janela de corte de torque
    parameter [15:0]         T_ENGAGE      = 16'd40,   // engate (solenoides/embreagem)
    parameter [15:0]         T_RESTORE     = 16'd20,   // restauracao de torque
    parameter [15:0]         SAMPLE_CYCLES = 16'd256,  // janela do estimador de inclinacao
    parameter signed [7:0]   ACLIVE_TH     = 8'sd4,    // limiar p/ considerar aclive
    parameter signed [7:0]   DECLIVE_TH    = -8'sd4    // limiar p/ considerar declive
)(
    input             clk,
    input             rst,

    // Sensores / entradas do "veiculo"
    input  [15:0]     sensor_rpm,
    input  [7:0]      sensor_tps,
    input  [7:0]      sensor_map,
    input  [15:0]     vehicle_speed,
    input             brake,
    input  [7:0]      drive_mode,        // [1:0]=seletor, [2]=sport

    // Atuadores / saidas da TCU
    output reg [7:0]  target_gear,       // marcha-alvo (0=N,1..5,6=R)
    output reg [7:0]  current_gear,      // marcha atual engatada
    output reg [7:0]  shift_solenoids,   // padrao de solenoides de troca
    output reg [7:0]  clutch_pressure,   // pressao de embreagem (0..255)
    output reg        shifting,          // 1 = troca em andamento (lock)
    output reg        torque_cut,        // 1 = pedido de corte de torque
    output signed [7:0] incline_est      // inclinacao estimada (observabilidade)
);

    // ----------------------------------------------------------------------
    // Constantes de seletor e offsets de conforto
    // ----------------------------------------------------------------------
    localparam [1:0] SEL_P = 2'd0, SEL_R = 2'd1, SEL_N = 2'd2, SEL_D = 2'd3;

    localparam [1:0] S_DRIVE   = 2'd0,  // marcha estavel
                     S_CUT     = 2'd1,  // corte de torque antes do engate
                     S_ENGAGE  = 2'd2,  // engate (solenoides + embreagem)
                     S_RESTORE = 2'd3;  // restauracao de torque

    localparam [15:0] SPORT_UP    = 16'd15; // sport: sobe limiar de subida
    localparam [15:0] SPORT_DN    = 16'd10; // sport: segura mais antes de descer
    localparam [15:0] RAMP_UP     = 16'd20; // aclive: atrasa subida
    localparam [15:0] RAMP_DN     = 16'd12; // aclive: adianta descida
    localparam [15:0] DECLIVE_HLD = 16'd20; // declive: segura marcha baixa
    localparam [15:0] BRAKE_HLD   = 16'd16; // freio: favorece freio-motor

    localparam [7:0]  CLUTCH_FULL = 8'd255; // embreagem totalmente acoplada
    localparam [7:0]  CLUTCH_SLIP = 8'd64;  // embreagem em deslizamento (troca)

    // ----------------------------------------------------------------------
    // Estimador de inclinacao (modulo isolado)
    // ----------------------------------------------------------------------
    tcu_incline_estimator #(.SAMPLE_CYCLES(SAMPLE_CYCLES)) est (
        .clk(clk), .rst(rst),
        .vehicle_speed(vehicle_speed),
        .sensor_map(sensor_map),
        .sensor_rpm(sensor_rpm),
        .incline_est(incline_est)
    );

    // ----------------------------------------------------------------------
    // Funcoes do shift map / histerese
    // tps_band: 0=0-24%, 1=25-49%, 2=50-74%, 3=75-100%
    // ----------------------------------------------------------------------
    function [1:0] tps_band(input [7:0] tps);
        begin
            if      (tps < 8'd25) tps_band = 2'd0;
            else if (tps < 8'd50) tps_band = 2'd1;
            else if (tps < 8'd75) tps_band = 2'd2;
            else                  tps_band = 2'd3;
        end
    endfunction

    // Limiar de SUBIDA: velocidade para subir de `gear` para `gear+1`.
    // Retorna 0xFFFF quando nao ha subida possivel (gear >= N_FWD).
    function [15:0] up_base(input [1:0] band, input [3:0] gear);
        begin
            up_base = 16'hFFFF;
            case (band)
                2'd0: case (gear) // carga baixa: troca cedo (economico/suave)
                        4'd1: up_base = 16'd15;
                        4'd2: up_base = 16'd30;
                        4'd3: up_base = 16'd50;
                        4'd4: up_base = 16'd70;
                      endcase
                2'd1: case (gear)
                        4'd1: up_base = 16'd20;
                        4'd2: up_base = 16'd40;
                        4'd3: up_base = 16'd65;
                        4'd4: up_base = 16'd90;
                      endcase
                2'd2: case (gear)
                        4'd1: up_base = 16'd28;
                        4'd2: up_base = 16'd52;
                        4'd3: up_base = 16'd80;
                        4'd4: up_base = 16'd110;
                      endcase
                2'd3: case (gear) // pe fundo: segura cada marcha mais alto (torque)
                        4'd1: up_base = 16'd35;
                        4'd2: up_base = 16'd65;
                        4'd3: up_base = 16'd95;
                        4'd4: up_base = 16'd130;
                      endcase
            endcase
        end
    endfunction

    // Limiar de DESCIDA: velocidade abaixo da qual desce de `gear` p/ `gear-1`.
    // Retorna 0 quando nao ha descida possivel (gear <= 1).
    // Por construcao dn_base(g+1) < up_base(g): isso cria o vao de histerese.
    function [15:0] dn_base(input [1:0] band, input [3:0] gear);
        begin
            dn_base = 16'd0;
            case (band)
                2'd0: case (gear)
                        4'd2: dn_base = 16'd8;
                        4'd3: dn_base = 16'd22;
                        4'd4: dn_base = 16'd40;
                        4'd5: dn_base = 16'd58;
                      endcase
                2'd1: case (gear)
                        4'd2: dn_base = 16'd12;
                        4'd3: dn_base = 16'd30;
                        4'd4: dn_base = 16'd52;
                        4'd5: dn_base = 16'd75;
                      endcase
                2'd2: case (gear)
                        4'd2: dn_base = 16'd18;
                        4'd3: dn_base = 16'd42;
                        4'd4: dn_base = 16'd66;
                        4'd5: dn_base = 16'd92;
                      endcase
                2'd3: case (gear)
                        4'd2: dn_base = 16'd24;
                        4'd3: dn_base = 16'd52;
                        4'd4: dn_base = 16'd80;
                        4'd5: dn_base = 16'd110;
                      endcase
            endcase
        end
    endfunction

    // ----------------------------------------------------------------------
    // Registradores de estado da FSM
    // ----------------------------------------------------------------------
    reg [1:0]  state;
    reg [15:0] timer;       // conta as fases CUT/ENGAGE/RESTORE
    reg [15:0] dwell;       // conta tempo na marcha (em S_DRIVE)

    // Sinais combinacionais de decisao
    reg [3:0]  cur_fwd;     // marcha a frente efetiva (1..N_FWD)
    reg [1:0]  band;
    reg [15:0] up_th, dn_th;
    reg        aclive, declive, block_up;
    reg [3:0]  desired;
    reg [1:0]  sel;
    reg        sport;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state           <= S_DRIVE;
            timer           <= 16'd0;
            dwell           <= 16'd0;
            target_gear     <= 8'd0;   // N
            current_gear    <= 8'd0;   // N
            shift_solenoids <= 8'd0;
            clutch_pressure <= CLUTCH_FULL;
            shifting        <= 1'b0;
            torque_cut      <= 1'b0;
        end else begin
            sel   = drive_mode[1:0];
            sport = drive_mode[2];

            // ----- Modos sem troca automatica (P / N / R) -----
            if (sel != SEL_D) begin
                state           <= S_DRIVE;
                timer           <= 16'd0;
                dwell           <= 16'd0;
                shifting        <= 1'b0;
                torque_cut      <= 1'b0;
                shift_solenoids <= 8'd0;
                clutch_pressure <= CLUTCH_FULL;
                if (sel == SEL_R) begin
                    target_gear  <= 8'd6;  // R
                    current_gear <= 8'd6;
                end else begin             // P ou N
                    target_gear  <= 8'd0;  // N
                    current_gear <= 8'd0;
                end
            end else begin
                // ----- Modo D: troca automatica -----
                case (state)
                    // ----------------------------------------------------
                    S_DRIVE: begin
                        // Ao entrar em D, engata a 1a marcha
                        if (current_gear < 8'd1 || current_gear > N_FWD[7:0]) begin
                            current_gear <= 8'd1;
                            target_gear  <= 8'd1;
                            dwell        <= 16'd0;
                        end else begin
                            cur_fwd = current_gear[3:0];
                            band    = tps_band(sensor_tps);

                            // limiares base
                            up_th = up_base(band, cur_fwd);
                            dn_th = dn_base(band, cur_fwd);

                            // modo sport segura marchas mais alto
                            if (sport) begin
                                if (up_th != 16'hFFFF) up_th = up_th + SPORT_UP;
                                dn_th = dn_th + SPORT_DN;
                            end

                            // compensacao de rampa
                            aclive   = (incline_est >= ACLIVE_TH);
                            declive  = (incline_est <= DECLIVE_TH);
                            block_up = declive | brake;  // declive/freio nunca sobe

                            if (aclive) begin
                                if (up_th != 16'hFFFF) up_th = up_th + RAMP_UP;
                                dn_th = dn_th + RAMP_DN;
                            end
                            if (declive) dn_th = dn_th + DECLIVE_HLD;
                            if (brake)   dn_th = dn_th + BRAKE_HLD;

                            // decisao de marcha-alvo (uma marcha por vez)
                            if (!block_up && cur_fwd < N_FWD[3:0] &&
                                {16'd0, vehicle_speed} >= {16'd0, up_th})
                                desired = cur_fwd + 4'd1;
                            else if (cur_fwd > 4'd1 &&
                                     {16'd0, vehicle_speed} < {16'd0, dn_th})
                                desired = cur_fwd - 4'd1;
                            else
                                desired = cur_fwd;

                            // dwell: conta tempo na marcha (satura)
                            if (dwell < DWELL_MIN) dwell <= dwell + 16'd1;

                            // dispara troca apenas se mudou E dwell cumprido
                            if (desired != cur_fwd && dwell >= DWELL_MIN) begin
                                target_gear <= {4'd0, desired};
                                shifting    <= 1'b1;
                                torque_cut  <= 1'b1;          // inicia corte de torque
                                clutch_pressure <= CLUTCH_SLIP;
                                timer       <= 16'd0;
                                state       <= S_CUT;
                            end else begin
                                shifting   <= 1'b0;
                                torque_cut <= 1'b0;
                            end
                        end
                    end

                    // ----------------------------------------------------
                    // Corte de torque ja ativo; aguarda janela e engata
                    S_CUT: begin
                        torque_cut <= 1'b1;
                        if (timer >= T_CUT) begin
                            shift_solenoids <= target_gear; // aciona solenoides
                            current_gear    <= target_gear; // marcha mecanicamente trocada
                            timer           <= 16'd0;
                            state           <= S_ENGAGE;
                        end else begin
                            timer <= timer + 16'd1;
                        end
                    end

                    // ----------------------------------------------------
                    // Engate: embreagem reacopla gradualmente
                    S_ENGAGE: begin
                        if (clutch_pressure < CLUTCH_FULL)
                            clutch_pressure <= clutch_pressure + 8'd4;
                        if (timer >= T_ENGAGE) begin
                            timer <= 16'd0;
                            state <= S_RESTORE;
                        end else begin
                            timer <= timer + 16'd1;
                        end
                    end

                    // ----------------------------------------------------
                    // Restauracao de torque e fim da troca
                    S_RESTORE: begin
                        torque_cut      <= 1'b0;           // restaura torque
                        clutch_pressure <= CLUTCH_FULL;
                        shift_solenoids <= 8'd0;
                        if (timer >= T_RESTORE) begin
                            shifting <= 1'b0;
                            dwell    <= 16'd0;             // reinicia dwell apos a troca
                            timer    <= 16'd0;
                            state    <= S_DRIVE;
                        end else begin
                            timer <= timer + 16'd1;
                        end
                    end
                endcase
            end
        end
    end

endmodule
