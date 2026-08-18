module cpu_debug_tb();

reg clk, rst;
wire [7:0] ignition_advance;
wire [15:0] injection_time;
wire ignition_trigger;
wire [7:0] safety_flags;

// Sensores fixos para teste
wire [15:0] sensor_rpm = 16'd800;
wire [7:0] sensor_tps = 8'd50;  // 50% TPS
wire [7:0] sensor_temp_motor = 8'd90;
wire [7:0] sensor_temp_ar = 8'd25;
wire [7:0] sensor_map = 8'd50;
wire sensor_tdc = 1'b0;

// Instância da CPU
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

// Clock generation
initial clk = 0;
always #5 clk = ~clk;

initial begin
    $display("Teste de depuração da CPU");
    $display("Sensores fixos: RPM=800, TPS=50");
    $display("Resultado esperado: Advance=20+5=25, Injection=960+250=1210");
    $display("");
    
    // Reset
    rst = 1;
    #20;
    rst = 0;
    
    // Aguardar execução
    #500;
    
    $display("Após 500 ciclos:");
    $display("Advance atual: %d (esperado ~25)", ignition_advance);
    $display("Injection atual: %d (esperado ~1210)", injection_time);
    $display("Flags: %b", safety_flags);
    
    #500;
    $display("\nApós 1000 ciclos:");
    $display("Advance: %d", ignition_advance);
    $display("Injection: %d", injection_time);
    
    $finish;
end

endmodule
