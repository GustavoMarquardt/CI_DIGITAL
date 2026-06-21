module debug_tb();

reg clk, rst;
reg [2:0] test_scenario;

wire [7:0] ignition_advance;
wire [15:0] injection_time;
wire ignition_trigger;
wire [7:0] safety_flags;
wire [15:0] sensor_rpm;
wire [7:0] sensor_tps;
wire [7:0] sensor_temp_motor;
wire [7:0] sensor_temp_ar;
wire [7:0] sensor_map;
wire sensor_tdc;

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

initial clk = 0;
always #5 clk = ~clk;

initial begin
    $display("=== DEBUG CENARIO 1 (IDLE) ===");
    
    rst = 1;
    test_scenario = 3'd0; // IDLE
    #20;
    rst = 0;
    
    #100;
    $display("T=%0t | RPM=%d TPS=%d Temp=%d MAP=%d", $time, sensor_rpm, sensor_tps, sensor_temp_motor, sensor_map);
    $display("       | Adv=%d Inj=%d Flags=%b", ignition_advance, injection_time, safety_flags);
    $display("Verificacao: RPM=800 < 6500? %b, Temp=90 < 120? %b", (sensor_rpm < 6500), (sensor_temp_motor < 120));
    $display("");
    
    #400;
    $display("T=%0t | RPM=%d TPS=%d Temp=%d MAP=%d", $time, sensor_rpm, sensor_tps, sensor_temp_motor, sensor_map);
    $display("       | Adv=%d Inj=%d Flags=%b", ignition_advance, injection_time, safety_flags);
    $display("");
    
    if (safety_flags == 0 && ignition_advance >= 10 && ignition_advance <= 20) begin
        $display("[OK] Cenario 1 funcionando corretamente");
    end else begin
        $display("[ERRO] Cenario 1 FALHOU");
        $display("       Flags=%b (esperado: 00000000)", safety_flags);
        $display("       Adv=%d (esperado: 10-20)", ignition_advance);
    end
    
    $finish;
end

endmodule
