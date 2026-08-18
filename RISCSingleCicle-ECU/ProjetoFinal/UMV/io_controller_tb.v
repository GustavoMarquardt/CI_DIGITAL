module io_controller_tb();

reg clk, rst;
reg [31:0] address;
reg [31:0] write_data;
reg write_enable;
wire [31:0] read_data;

// Sensores simulados
reg [15:0] sensor_rpm;
reg [7:0] sensor_tps;
reg [7:0] sensor_temp_motor;
reg [7:0] sensor_temp_ar;
reg [7:0] sensor_map;
reg sensor_tdc;

// Atuadores
wire [7:0] ignition_advance;
wire [15:0] injection_time;
wire ignition_trigger;
wire [7:0] safety_flags;

// Instância do DUT
io_controller dut (
    .clk(clk),
    .rst(rst),
    .address(address),
    .write_data(write_data),
    .write_enable(write_enable),
    .read_data(read_data),
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

// Clock
initial clk = 0;
always #5 clk = ~clk;

// Teste
initial begin
    $display("=== Testbench do I/O Controller ===");
    $display("");
    
    // Inicialização
    rst = 1;
    write_enable = 0;
    address = 0;
    write_data = 0;
    
    // Sensores simulados
    sensor_rpm = 3000;
    sensor_tps = 50;
    sensor_temp_motor = 90;
    sensor_temp_ar = 25;
    sensor_map = 60;
    sensor_tdc = 0;
    
    #20;
    rst = 0;
    #10;
    
    //===========================================
    // TESTE 1: Leitura de Sensores
    //===========================================
    $display("TESTE 1: Leitura de Sensores");
    $display("------------------------------");
    
    // Ler RPM
    address = 32'h00001000;
    #10;
    $display("RPM lido: %d (esperado: 3000)", read_data);
    
    // Ler TPS
    address = 32'h00001004;
    #10;
    $display("TPS lido: %d (esperado: 50)", read_data);
    
    // Ler Temp Motor
    address = 32'h00001008;
    #10;
    $display("Temp Motor lido: %d (esperado: 90)", read_data);
    
    // Ler Temp Ar
    address = 32'h0000100C;
    #10;
    $display("Temp Ar lido: %d (esperado: 25)", read_data);
    
    // Ler MAP
    address = 32'h00001010;
    #10;
    $display("MAP lido: %d (esperado: 60)", read_data);
    
    // Ler TDC
    address = 32'h00001014;
    #10;
    $display("TDC lido: %d (esperado: 0)", read_data);
    
    $display("");
    
    //===========================================
    // TESTE 2: Escrita em Atuadores
    //===========================================
    $display("TESTE 2: Escrita em Atuadores");
    $display("-------------------------------");
    
    // Escrever Avanço de Ignição
    address = 32'h00002000;
    write_data = 32'd25;
    write_enable = 1;
    #10;
    write_enable = 0;
    #10;
    $display("Avanço escrito: 25, lido: %d", ignition_advance);
    
    // Escrever Tempo de Injeção
    address = 32'h00002004;
    write_data = 32'd1500;
    write_enable = 1;
    #10;
    write_enable = 0;
    #10;
    $display("Tempo injeção escrito: 1500, lido: %d", injection_time);
    
    // Escrever Trigger de Ignição
    address = 32'h00002008;
    write_data = 32'd1;
    write_enable = 1;
    #10;
    write_enable = 0;
    #10;
    $display("Trigger escrito: 1, lido: %d", ignition_trigger);
    
    // Desligar trigger
    address = 32'h00002008;
    write_data = 32'd0;
    write_enable = 1;
    #10;
    write_enable = 0;
    #10;
    $display("Trigger escrito: 0, lido: %d", ignition_trigger);
    
    // Escrever Safety Flags
    address = 32'h00002010;
    write_data = 32'b00000011;
    write_enable = 1;
    #10;
    write_enable = 0;
    #10;
    $display("Safety flags escritas: 3, lidas: %d", safety_flags);
    
    $display("");
    
    //===========================================
    // TESTE 3: Mudança de Sensores
    //===========================================
    $display("TESTE 3: Mudança Dinâmica de Sensores");
    $display("---------------------------------------");
    
    sensor_rpm = 5000;
    sensor_tps = 80;
    sensor_tdc = 1;
    #10;
    
    address = 32'h00001000;
    #10;
    $display("RPM atualizado: %d (esperado: 5000)", read_data);
    
    address = 32'h00001004;
    #10;
    $display("TPS atualizado: %d (esperado: 80)", read_data);
    
    address = 32'h00001014;
    #10;
    $display("TDC atualizado: %d (esperado: 1)", read_data);
    
    $display("");
    
    //===========================================
    // TESTE 4: Limites e Condições Extremas
    //===========================================
    $display("TESTE 4: Condições Extremas");
    $display("-----------------------------");
    
    // RPM máximo
    sensor_rpm = 16'd7000;
    address = 32'h00001000;
    #10;
    $display("RPM máximo: %d", read_data);
    
    // TPS máximo
    sensor_tps = 8'd100;
    address = 32'h00001004;
    #10;
    $display("TPS máximo: %d", read_data);
    
    // Temperatura alta
    sensor_temp_motor = 8'd130;
    address = 32'h00001008;
    #10;
    $display("Temp crítica: %d", read_data);
    
    $display("");
    $display("=== Teste Concluído ===");
    
    #50;
    $finish;
end

endmodule
