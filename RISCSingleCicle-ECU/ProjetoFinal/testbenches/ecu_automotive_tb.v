module ecu_automotive_tb();

// Sinais do clock e reset
reg clk, rst;

// Sinais dos sensores
wire [15:0] sensor_rpm;
wire [7:0] sensor_tps;
wire [7:0] sensor_temp_motor;
wire [7:0] sensor_temp_ar;
wire [7:0] sensor_map;
wire sensor_tdc;

// Sinais dos atuadores
wire [7:0] ignition_advance;
wire [15:0] injection_time;
wire ignition_trigger;
wire [7:0] safety_flags;

// Seleção de cenário de teste
reg [2:0] test_scenario;

// Clock 10 ns; laço firmware ~89 instr ≈ 890 ns — aguardar vários laços + evolução do sensor
localparam integer CLK_PERIOD_NS = 10;
localparam integer ECU_SETTLE_NS = 12000;   // ≈1200 ciclos, ~13 laços
localparam integer ECU_LONG_NS   = 20000;  // cold / overheat com rampa
localparam integer ACCEL_SETTLE_NS = 35000; // aceleração: platô máximo RPM/TPS + margem
localparam integer OVERREV_LOW_NS  = 1800; // ciclo_sensor < 200 → RPM 5000
localparam integer OVERREV_HIGH_NS = 8000; // ciclo_sensor >= 200 → RPM >= 6500 + tempo CPU

// Overheat: temp=80 só enquanto cycle_counter < 100 (1000 ns); não usar ECU_SETTLE na 1ª fase
localparam integer OVERHEAT_T80_MAX_NS = 900;
localparam integer OVERHEAT_TO_HOT_NS  = 18000;

// Variáveis auxiliares para testes
reg [7:0] adv_sample1, adv_sample2, adv_sample3;
integer passed_tests;
integer failed_tests;

// Instância do simulador de sensores
sensor_simulator sensors (
    .clk(clk),
    .rst(rst),
    .test_scenario(test_scenario),
    .sensor_rpm(sensor_rpm),
    .sensor_tps(sensor_tps),
    .sensor_temp_motor(sensor_temp_motor),
    .sensor_temp_ar(sensor_temp_ar),
    .sensor_map(sensor_map),
    .sensor_tdc(sensor_tdc)
);

// Instância da CPU (ECU)
cpu ecu (
    .clk(clk),
    .rst(rst),
    .sensor_rpm(sensor_rpm),
    .sensor_tps(sensor_tps),
    .sensor_temp_motor(sensor_temp_motor),
    .sensor_temp_ar(sensor_temp_ar),
    .sensor_map(sensor_map),
    .sensor_tdc(sensor_tdc),
    .ignition_advance(ignition_advance),
    .injection_time(injection_time),
    .ignition_trigger(ignition_trigger),
    .safety_flags(safety_flags)
);

// Geração do clock (100 MHz = 10ns período)
initial clk = 0;
always #5 clk = ~clk;

// Monitor de valores
always @(posedge clk) begin
    if (!rst) begin
        $display("T=%0t | RPM=%d TPS=%d TempM=%d TempA=%d MAP=%d | Adv=%d Inj=%d Trig=%b Flags=%b",
                 $time, sensor_rpm, sensor_tps, sensor_temp_motor, sensor_temp_ar, sensor_map,
                 ignition_advance, injection_time, ignition_trigger, safety_flags);
    end
end

// Sequência de testes
initial begin
    passed_tests = 0;
    failed_tests = 0;
    
    $display("========================================================================");
    $display("     ECU AUTOMOTIVE TESTBENCH - Motor Monocilindrico");
    $display("========================================================================");
    $display("");
    
    rst = 1;
    test_scenario = 0;
    #20;
    rst = 0;
    
    //==========================================================================
    // CENÁRIO 1: MARCHA LENTA (IDLE)
    //==========================================================================
    $display("");
    $display("========================================================================");
    $display("CENARIO 1: MARCHA LENTA (IDLE)");
    $display("========================================================================");
    $display("Objetivo: Validar operacao estavel em marcha lenta");
    $display("Condicoes: RPM=800, TPS=0%%, Temp=90C");
    $display("");
    
    test_scenario = 3'd0; // IDLE
    #(ECU_SETTLE_NS);
    
    // Validação
    if (sensor_rpm == 800 && ignition_advance >= 10 && ignition_advance <= 20) begin
        $display("[PASS] Avanco de ignicao adequado para marcha lenta");
        passed_tests = passed_tests + 1;
    end else begin
        $display("[FAIL] Avanco de ignicao fora do esperado (Avanco=%d, esperado: 10-20)", ignition_advance);
        failed_tests = failed_tests + 1;
    end
    
    //==========================================================================
    // CENÁRIO 2: ARRANQUE A FRIO (COLD START)
    //==========================================================================
    $display("");
    $display("========================================================================");
    $display("CENARIO 2: ARRANQUE A FRIO");
    $display("========================================================================");
    $display("Objetivo: Validar enriquecimento de mistura e avanco reduzido");
    $display("Condicoes: Temp inicial=20C, aquecimento gradual");
    $display("");
    
    rst = 1;
    #20;
    rst = 0;
    test_scenario = 3'd1; // COLD_START
    #(ECU_LONG_NS);
    
    // Validação
    if (injection_time > 1000) begin
        $display("[PASS] Tempo de injecao aumentado para motor frio (Inj=%d)", injection_time);
        passed_tests = passed_tests + 1;
    end else begin
        $display("[FAIL] Tempo de injecao nao foi ajustado adequadamente (Inj=%d, esperado: >1000)", injection_time);
        failed_tests = failed_tests + 1;
    end
    
    //==========================================================================
    // CENÁRIO 3: ACELERAÇÃO GRADUAL
    //==========================================================================
    $display("");
    $display("========================================================================");
    $display("CENARIO 3: ACELERACAO GRADUAL");
    $display("========================================================================");
    $display("Objetivo: Validar aumento progressivo de ignicao e injecao");
    $display("Condicoes: TPS 0%%->100%%, RPM 1000->6000");
    $display("");
    
    rst = 1;
    #20;
    rst = 0;
    test_scenario = 3'd2; // ACCELERATION
    
    // Monitorar valores iniciais
    #(5 * CLK_PERIOD_NS);
    $display("Inicio: RPM=%d, TPS=%d%%, Avanco=%d", sensor_rpm, sensor_tps, ignition_advance);
    
    #(ACCEL_SETTLE_NS);
    
    // Validação
    if (ignition_advance >= 20 && ignition_advance <= 35) begin
        $display("[PASS] Avanco aumentou adequadamente durante aceleracao (Avanco=%d)", ignition_advance);
        passed_tests = passed_tests + 1;
    end else begin
        $display("[FAIL] Avanco nao atingiu valores esperados (Avanco=%d, esperado: 20-35)", ignition_advance);
        failed_tests = failed_tests + 1;
    end
    
    //==========================================================================
    // CENÁRIO 4: REGIME DE CRUZEIRO (CRUISE)
    //==========================================================================
    $display("");
    $display("========================================================================");
    $display("CENARIO 4: REGIME DE CRUZEIRO");
    $display("========================================================================");
    $display("Objetivo: Validar estabilidade em regime constante");
    $display("Condicoes: RPM=3000, TPS=40%%, estavel");
    $display("");
    
    rst = 1;
    #20;
    rst = 0;
    test_scenario = 3'd3; // CRUISE
    #(ECU_SETTLE_NS);
    
    // Capturar valores para verificar estabilidade
    adv_sample1 = ignition_advance;
    #(20 * CLK_PERIOD_NS);
    adv_sample2 = ignition_advance;
    #(20 * CLK_PERIOD_NS);
    adv_sample3 = ignition_advance;
    
    // Validação
    if (adv_sample1 == adv_sample2 && adv_sample2 == adv_sample3) begin
        $display("[PASS] Valores estaveis em cruzeiro (Avanco=%d)", adv_sample1);
        passed_tests = passed_tests + 1;
    end else begin
        $display("[FAIL] Instabilidade detectada em cruzeiro (Amostras: %d, %d, %d)", adv_sample1, adv_sample2, adv_sample3);
        failed_tests = failed_tests + 1;
    end
    
    //==========================================================================
    // CENÁRIO 5: PROTEÇÃO DE OVER-REV
    //==========================================================================
    $display("");
    $display("========================================================================");
    $display("CENÁRIO 5: PROTEÇÃO DE OVER-REV");
    $display("========================================================================");
    $display("Objetivo: Validar limitador de RPM (rev limiter)");
    $display("Condições: RPM ultrapassa 6500");
    $display("");
    
    rst = 1;
    #20;
    rst = 0;
    test_scenario = 3'd4; // OVERREV
    
    #(OVERREV_LOW_NS); // cycle_counter < 200 → RPM 5000
    $display("RPM normal: RPM=%d, Flags=%b, Inj=%d", sensor_rpm, safety_flags, injection_time);
    
    #(OVERREV_HIGH_NS); // cycle_counter >= 200 → RPM >= 6500 + vários laços CPU
    $display("Over-rev:   RPM=%d, Flags=%b, Inj=%d", sensor_rpm, safety_flags, injection_time);
    
    // Validação
    if (safety_flags & 8'b00000001) begin
        $display("[PASS] Flag de over-rev ativada corretamente");
        passed_tests = passed_tests + 1;
    end else begin
        $display("[FAIL] Flag de over-rev nao foi ativada (Flags=%b)", safety_flags);
        failed_tests = failed_tests + 1;
    end
    
    if (injection_time == 0 || injection_time < 500) begin
        $display("[PASS] Injecao cortada/reduzida durante over-rev (Inj=%d)", injection_time);
        passed_tests = passed_tests + 1;
    end else begin
        $display("[FAIL] Injecao nao foi cortada adequadamente (Inj=%d, esperado: <500)", injection_time);
        failed_tests = failed_tests + 1;
    end
    
    //==========================================================================
    // CENÁRIO 6: PROTEÇÃO DE SUPERAQUECIMENTO (OVERHEAT)
    //==========================================================================
    $display("");
    $display("========================================================================");
    $display("CENARIO 6: PROTECAO DE SUPERAQUECIMENTO");
    $display("========================================================================");
    $display("Objetivo: Validar modo de seguranca por temperatura excessiva");
    $display("Condicoes: Temperatura sobe de 80C para 125C");
    $display("");
    
    rst = 1;
    #20;
    rst = 0;
    test_scenario = 3'd5; // OVERHEAT
    
    // Manter cycle_counter < 100 para temp_motor = 80; ~89 instr ≈ 890 ns
    #(OVERHEAT_T80_MAX_NS);
    $display("Temp normal: Temp=%dC, Flags=%b, Avanco=%d", sensor_temp_motor, safety_flags, ignition_advance);
    
    #(OVERHEAT_TO_HOT_NS);
    $display("Temp alta:   Temp=%dC, Flags=%b, Avanco=%d", sensor_temp_motor, safety_flags, ignition_advance);
    
    // Validação
    if (safety_flags & 8'b00000010) begin
        $display("[PASS] Flag de overheat ativada corretamente");
        passed_tests = passed_tests + 1;
    end else begin
        $display("[FAIL] Flag de overheat nao foi ativada (Flags=%b)", safety_flags);
        failed_tests = failed_tests + 1;
    end
    
    if (ignition_advance <= 10) begin
        $display("[PASS] Avanco reduzido para protecao termica (Avanco=%d)", ignition_advance);
        passed_tests = passed_tests + 1;
    end else begin
        $display("[FAIL] Avanco nao foi reduzido adequadamente (Avanco=%d, esperado: <=10)", ignition_advance);
        failed_tests = failed_tests + 1;
    end
    
    //==========================================================================
    // RESUMO FINAL
    //==========================================================================
    $display("");
    $display("========================================================================");
    $display("                    RESUMO DOS TESTES");
    $display("========================================================================");
    $display("Total de testes executados: %0d", passed_tests + failed_tests);
    $display("Testes PASSADOS: %0d", passed_tests);
    $display("Testes FALHADOS: %0d", failed_tests);
    $display("");
    if (failed_tests == 0) begin
        $display(">>> TODOS OS TESTES PASSARAM! <<<");
    end else begin
        $display(">>> ALGUNS TESTES FALHARAM <<<");
    end
    $display("");
    $display("Arquitetura: Processador RISC-V Single-Cycle");
    $display("Aplicacao: ECU para Motor Monocilindrico");
    $display("Controles: Ignicao + Injecao + Safety");
    $display("========================================================================");
    $display("");
    
    #100;
    $finish;
end

// Monitor de eventos TDC
always @(posedge sensor_tdc) begin
    if (!rst) begin
        $display("[TDC] Ponto morto superior detectado - RPM=%d", sensor_rpm);
    end
end

// Monitor de trigger de ignição
always @(posedge ignition_trigger) begin
    if (!rst) begin
        $display("[IGN] Ignição disparada - Avanço=%d° @ RPM=%d", ignition_advance, sensor_rpm);
    end
end

// Dump de sinais para análise (opcional)
initial begin
    $dumpfile("ecu_automotive_tb.vcd");
    $dumpvars(0, ecu_automotive_tb);
end

endmodule
