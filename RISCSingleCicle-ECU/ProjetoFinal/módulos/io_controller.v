module io_controller (
    input clk, rst,
    input [31:0] address,
    input [31:0] write_data,
    input write_enable,
    output reg [31:0] read_data,

    // Sensores (entradas simuladas) - ignicao/injecao
    input [15:0] sensor_rpm,
    input [7:0] sensor_tps,
    input [7:0] sensor_temp_motor,
    input [7:0] sensor_temp_ar,
    input [7:0] sensor_map,
    input sensor_tdc,

    // Sensores / entradas adicionais da TCU (cambio)
    input [15:0] vehicle_speed,
    input        brake,
    input [7:0]  drive_mode,

    // Atuadores (saidas) - ignicao/injecao
    output [7:0] ignition_advance,   // saida final (ja com mux de torque-cut)
    output [15:0] injection_time,    // saida final (ja com mux de torque-cut)
    output reg ignition_trigger,
    output reg [7:0] safety_flags
);

// ===========================================================================
// Mapeamento de enderecos
// ---------------------------------------------------------------------------
// Leitura (Sensores / entradas) - 0x1000+:
//   0x1000: RPM (16)            0x1004: TPS (8)
//   0x1008: Temp Motor (8)      0x100C: Temp Ar (8)
//   0x1010: MAP (8)             0x1014: TDC (1)
//   0x1018: Velocidade veiculo (16)   [TCU]
//   0x101C: Freio (1)                 [TCU]
//   0x1020: Seletor/modo (8)          [TCU]
//
// Escrita/Leitura (Atuadores) - 0x2000+:
//   0x2000: Avanco de Ignicao (8)  0x2004: Tempo de Injecao (16)
//   0x2008: Trigger (1)            0x2010: Safety Flags (8, r/w)
//   --- saidas da TCU (read-only, refletem o tcu_controller) ---
//   0x2014: Marcha-alvo (8)        0x2018: Solenoides de troca (8)
//   0x201C: Pressao de embreagem (8)
//   0x2020: Status TCU (8): {shifting, torque_cut, current_gear[5:0]}
//   0x2024: Inclinacao estimada (8, signed, sign-extended na leitura)
// ===========================================================================

// Comandos de ignicao/injecao escritos pela CPU (antes do mux de torque-cut)
reg [7:0]  adv_cmd;
reg [15:0] inj_cmd;

// Saidas da TCU
wire [7:0]  tcu_target_gear;
wire [7:0]  tcu_current_gear;
wire [7:0]  tcu_solenoids;
wire [7:0]  tcu_clutch;
wire        tcu_shifting;
wire        tcu_torque_cut;
wire signed [7:0] tcu_incline;

// ---------------------------------------------------------------------------
// Instancia da TCU (cambio automatico) - roda em hardware, em paralelo
// ao firmware de ignicao/injecao da CPU.
// ---------------------------------------------------------------------------
tcu_controller tcu (
    .clk(clk), .rst(rst),
    .sensor_rpm(sensor_rpm),
    .sensor_tps(sensor_tps),
    .sensor_map(sensor_map),
    .vehicle_speed(vehicle_speed),
    .brake(brake),
    .drive_mode(drive_mode),
    .target_gear(tcu_target_gear),
    .current_gear(tcu_current_gear),
    .shift_solenoids(tcu_solenoids),
    .clutch_pressure(tcu_clutch),
    .shifting(tcu_shifting),
    .torque_cut(tcu_torque_cut),
    .incline_est(tcu_incline)
);

// ---------------------------------------------------------------------------
// INTEGRACAO INJECAO + CAMBIO:
// durante a troca a TCU pede corte de torque (tcu_torque_cut). Aplicamos isso
// atrasando o avanco de ignicao para o minimo e cortando a injecao p/ 25%.
// Fora da troca, passam os comandos calculados pelo firmware (adv_cmd/inj_cmd).
// ---------------------------------------------------------------------------
assign ignition_advance = tcu_torque_cut ? 8'd5            : adv_cmd;
assign injection_time   = tcu_torque_cut ? (inj_cmd >> 2)  : inj_cmd;

// Inicializacao dos comandos
initial begin
    adv_cmd = 8'd15;
    inj_cmd = 16'd1000;
    ignition_trigger = 1'b0;
    safety_flags = 8'b0;
end

// Logica de leitura (assincrona)
always @(*) begin
    case (address)
        // Sensores de ignicao/injecao
        32'h00001000: read_data = {16'b0, sensor_rpm};
        32'h00001004: read_data = {24'b0, sensor_tps};
        32'h00001008: read_data = {24'b0, sensor_temp_motor};
        32'h0000100C: read_data = {24'b0, sensor_temp_ar};
        32'h00001010: read_data = {24'b0, sensor_map};
        32'h00001014: read_data = {31'b0, sensor_tdc};
        // Entradas da TCU
        32'h00001018: read_data = {16'b0, vehicle_speed};
        32'h0000101C: read_data = {31'b0, brake};
        32'h00001020: read_data = {24'b0, drive_mode};
        // Atuadores de ignicao/injecao
        32'h00002010: read_data = {24'b0, safety_flags};
        // Saidas da TCU (read-only)
        32'h00002014: read_data = {24'b0, tcu_target_gear};
        32'h00002018: read_data = {24'b0, tcu_solenoids};
        32'h0000201C: read_data = {24'b0, tcu_clutch};
        32'h00002020: read_data = {24'b0, tcu_shifting, tcu_torque_cut, tcu_current_gear[5:0]};
        32'h00002024: read_data = {{24{tcu_incline[7]}}, tcu_incline};
        default: read_data = 32'h0;
    endcase
end

// Escrita sincrona; reset limpa atuadores a cada cenario do testbench
always @(posedge clk or posedge rst) begin
    if (rst) begin
        adv_cmd <= 8'd15;
        inj_cmd <= 16'd1000;
        ignition_trigger <= 1'b0;
        safety_flags <= 8'b0;
    end else if (write_enable) begin
        if (address >= 32'h00002000 && address <= 32'h00002010) begin
            case (address)
                32'h00002000: adv_cmd <= write_data[7:0];
                32'h00002004: inj_cmd <= write_data[15:0];
                32'h00002008: ignition_trigger <= write_data[0];
                32'h00002010: safety_flags <= write_data[7:0];
                default: ;
            endcase
        end
    end
end

endmodule
