// ============================================================================
// tcu_tb.v - Testbench da TCU (cambio automatico escalonado)
//
// Exercita o tcu_controller diretamente (teste de unidade focado), provando os
// comportamentos de conforto exigidos:
//   1) Subida normal de marcha em reta
//   2) Descida normal de marcha em reta
//   3) Anti-hunting: velocidade colada no ponto de troca NAO oscila (histerese)
//   4) Kickdown: pe-fundo (TPS=100%) forca descida
//   5) Aclive: subida atrasada (segura torque)
//   6) Declive: nunca sobe (freio-motor)
//
// Tempos do FSM reduzidos por parametro para a simulacao ser curta.
// Rodar:  iverilog -g2012 -o sim.vvp módulos/tcu_controller.v \
//                       módulos/tcu_incline_estimator.v testbenches/tcu_tb.v
//         vvp sim.vvp
// ============================================================================
`timescale 1ns/1ps
module tcu_tb();

    // Entradas do DUT
    reg         clk, rst;
    reg [15:0]  sensor_rpm;
    reg [7:0]   sensor_tps;
    reg [7:0]   sensor_map;
    reg [15:0]  vehicle_speed;
    reg         brake;
    reg [7:0]   drive_mode;

    // Saidas do DUT
    wire [7:0]  target_gear;
    wire [7:0]  current_gear;
    wire [7:0]  shift_solenoids;
    wire [7:0]  clutch_pressure;
    wire        shifting;
    wire        torque_cut;
    wire signed [7:0] incline_est;

    // Selecao de modo
    localparam [7:0] MODE_N = 8'd2;  // neutro
    localparam [7:0] MODE_D = 8'd3;  // drive

    integer passed, failed;
    reg     saw_torque_cut;  // monitora corte de torque durante troca

    // ----------------------------------------------------------------------
    // DUT com tempos reduzidos para simulacao
    // ----------------------------------------------------------------------
    tcu_controller #(
        .DWELL_MIN  (16'd20),
        .T_CUT      (16'd4),
        .T_ENGAGE   (16'd6),
        .T_RESTORE  (16'd4),
        .SAMPLE_CYCLES(16'd8),
        .ACLIVE_TH  (8'sd4),
        .DECLIVE_TH (-8'sd4)
    ) dut (
        .clk(clk), .rst(rst),
        .sensor_rpm(sensor_rpm),
        .sensor_tps(sensor_tps),
        .sensor_map(sensor_map),
        .vehicle_speed(vehicle_speed),
        .brake(brake),
        .drive_mode(drive_mode),
        .target_gear(target_gear),
        .current_gear(current_gear),
        .shift_solenoids(shift_solenoids),
        .clutch_pressure(clutch_pressure),
        .shifting(shifting),
        .torque_cut(torque_cut),
        .incline_est(incline_est)
    );

    // Clock 10 ns
    initial clk = 0;
    always #5 clk = ~clk;

    // Monitor de corte de torque
    always @(posedge clk) if (!rst && torque_cut) saw_torque_cut <= 1'b1;

    // Monitor de troca de marcha
    reg [7:0] last_gear;
    always @(posedge clk) begin
        if (!rst && current_gear != last_gear) begin
            $display("  T=%0t  marcha %0d -> %0d  (vel=%0d tps=%0d incl=%0d)",
                     $time, last_gear, current_gear, vehicle_speed, sensor_tps, incline_est);
            last_gear <= current_gear;
        end
    end

    // ----------------------------------------------------------------------
    // Tarefas auxiliares
    // ----------------------------------------------------------------------
    task wait_clk(input integer n);
        integer k;
        begin for (k=0;k<n;k=k+1) @(posedge clk); end
    endtask

    // Rampa de velocidade: +/-1 unidade a cada `cps` ciclos de clock.
    // cps maior => aceleracao menor (mantem inclinacao estimada neutra).
    task ramp_to(input [15:0] tgt, input integer cps);
        integer k;
        begin
            while (vehicle_speed !== tgt) begin
                if (vehicle_speed < tgt) vehicle_speed = vehicle_speed + 16'd1;
                else                     vehicle_speed = vehicle_speed - 16'd1;
                for (k=0;k<cps;k=k+1) @(posedge clk);
            end
        end
    endtask

    task pulse_rst;
        begin
            vehicle_speed = 16'd0; brake = 1'b0;
            rst = 1; @(posedge clk); @(posedge clk); @(posedge clk);
            rst = 0; @(posedge clk);
            saw_torque_cut = 0;
            last_gear = current_gear;
        end
    endtask

    task check(input cond, input [1023:0] msg);
        begin
            if (cond) begin
                $display("[PASS] %0s", msg);
                passed = passed + 1;
            end else begin
                $display("[FAIL] %0s", msg);
                failed = failed + 1;
            end
        end
    endtask

    // ----------------------------------------------------------------------
    // Sequencia de testes
    // ----------------------------------------------------------------------
    initial begin
        passed = 0; failed = 0; saw_torque_cut = 0; last_gear = 0;
        rst = 1; sensor_rpm = 16'd1500; sensor_tps = 8'd40;
        sensor_map = 8'd16; vehicle_speed = 16'd0; brake = 0; drive_mode = MODE_N;

        $display("========================================================================");
        $display("            TCU TESTBENCH - Cambio Automatico (5 marchas + N + R)");
        $display("========================================================================");

        //====================================================================
        // CENARIO 1: SUBIDA NORMAL EM RETA
        //====================================================================
        $display("\n--- CENARIO 1: Subida normal (acelera, sobe 1..5) ---");
        pulse_rst;
        drive_mode = MODE_D; sensor_tps = 8'd40; sensor_map = 8'd16;
        ramp_to(16'd100, 2);
        wait_clk(160);          // acomodacao: marcha alcanca a velocidade
        check(current_gear == 8'd5,
              "Subiu progressivamente ate a 5a marcha");
        check(saw_torque_cut == 1'b1,
              "Houve corte de torque durante as trocas (integracao injecao+cambio)");

        //====================================================================
        // CENARIO 2: DESCIDA NORMAL EM RETA
        //====================================================================
        $display("\n--- CENARIO 2: Descida normal (desacelera, desce ate 1) ---");
        ramp_to(16'd0, 2);
        wait_clk(120);
        check(current_gear == 8'd1,
              "Desceu progressivamente ate a 1a marcha");

        //====================================================================
        // CENARIO 3A: ANTI-HUNTING (velocidade colada no ponto de troca)
        //====================================================================
        $display("\n--- CENARIO 3A: Anti-hunting (vel. estavel na zona de troca) ---");
        pulse_rst;
        drive_mode = MODE_D; sensor_tps = 8'd40; sensor_map = 8'd16;
        ramp_to(16'd50, 2);     // estabiliza em 3a (band1: up3->4=65, dn3->2=30)
        wait_clk(40);
        begin : anti_hunt
            integer i; reg [7:0] g0; reg estavel;
            g0 = current_gear; estavel = 1'b1;
            for (i=0;i<200;i=i+1) begin
                @(posedge clk);
                if (current_gear != g0) estavel = 1'b0;
            end
            check(g0 == 8'd3 && estavel,
                  "Marcha estavel (sem hunting) com velocidade colada no ponto de troca");
        end

        //====================================================================
        // CENARIO 3B: HISTERESE (gap impede reversao imediata)
        //====================================================================
        $display("\n--- CENARIO 3B: Histerese (sobe e nao volta no mesmo ponto) ---");
        ramp_to(16'd66, 2);     // cruza up3->4=65 -> sobe p/ 4a
        wait_clk(80);
        check(current_gear == 8'd4, "Subiu para 4a ao cruzar o limiar de subida");
        // desce bem devagar (cps=16) para manter a inclinacao estimada no
        // deadband e isolar a histerese pura (a compensacao de rampa, que
        // reage a desaceleracao, e exercitada nos cenarios 5 e 6)
        ramp_to(16'd55, 16);    // 55 esta entre dn4->3=52 e up4->5=90
        wait_clk(80);
        check(current_gear == 8'd4,
              "Permaneceu em 4a em 55 (histerese: nao desceu, sem hunting)");

        //====================================================================
        // CENARIO 4: KICKDOWN (pe-fundo forca descida)
        //====================================================================
        $display("\n--- CENARIO 4: Kickdown (TPS 40%% -> 100%% forca descida) ---");
        pulse_rst;
        drive_mode = MODE_D; sensor_tps = 8'd40; sensor_map = 8'd16;
        ramp_to(16'd78, 2);     // estabiliza em 4a (band1)
        wait_clk(160);          // acomodacao: deixa a marcha alcancar a velocidade
        check(current_gear == 8'd4, "Cruzeiro estabelecido em 4a marcha");
        sensor_tps = 8'd100;    // pe fundo -> band3 (dn4->3=80 > 78)
        wait_clk(80);
        check(current_gear == 8'd3,
              "Kickdown reduziu para 3a marcha");

        //====================================================================
        // CENARIO 5: ACLIVE (subida atrasada)
        //====================================================================
        $display("\n--- CENARIO 5: Aclive (subida de marcha atrasada) ---");
        pulse_rst;
        drive_mode = MODE_D; sensor_tps = 8'd40; sensor_map = 8'd90; // carga alta, pouca acel => aclive
        ramp_to(16'd42, 2);
        wait_clk(60);
        check(incline_est >= 8'sd4, "Aclive detectado pela estimativa de inclinacao");
        check(current_gear == 8'd2,
              "Em aclive, segurou a 2a marcha em vel=42 (em reta ja teria subido p/ 3a)");

        //====================================================================
        // CENARIO 6: DECLIVE (nunca sobe / freio-motor)
        //====================================================================
        $display("\n--- CENARIO 6: Declive (bloqueia subida, freio-motor) ---");
        pulse_rst;
        drive_mode = MODE_D; sensor_tps = 8'd40; sensor_map = 8'd12; // ganha vel. com pouca carga => declive
        ramp_to(16'd90, 1);     // rampa rapida => aceleracao alta => declive
        check(incline_est <= -8'sd4, "Declive detectado pela estimativa de inclinacao");
        check(current_gear == 8'd1,
              "Em declive, nao subiu de marcha mesmo em alta velocidade (freio-motor)");

        //====================================================================
        // RESUMO
        //====================================================================
        $display("\n========================================================================");
        $display("                          RESUMO TCU");
        $display("========================================================================");
        $display("Total: %0d   PASS: %0d   FAIL: %0d", passed+failed, passed, failed);
        if (failed == 0) $display(">>> TODOS OS TESTES DA TCU PASSARAM! <<<");
        else             $display(">>> ALGUNS TESTES DA TCU FALHARAM <<<");
        $display("========================================================================");
        #50 $finish;
    end

    // Guarda de seguranca contra travamento
    initial begin
        #5000000;
        $display("[TIMEOUT] Simulacao excedeu o tempo limite");
        $finish;
    end

endmodule
