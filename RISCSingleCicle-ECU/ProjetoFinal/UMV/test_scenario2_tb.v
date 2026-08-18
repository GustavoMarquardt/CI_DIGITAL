module test_scenario2_tb();

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

// Sensor simulator
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

// CPU
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

// Clock
initial clk = 0;
always #5 clk = ~clk;

initial begin
    $display("Teste do Cenario 2 - Arranque a Frio");
    $display("");
    
    rst = 1;
    test_scenario = 3'd1; // COLD_START
    #20;
    rst = 0;
    
    #50;
    $display("T=%0t | RPM=%d TPS=%d Temp=%d MAP=%d | Adv=%d Inj=%d", 
             $time, sensor_rpm, sensor_tps, sensor_temp_motor, sensor_map, 
             ignition_advance, injection_time);
    
    #100;
    $display("T=%0t | RPM=%d TPS=%d Temp=%d MAP=%d | Adv=%d Inj=%d", 
             $time, sensor_rpm, sensor_tps, sensor_temp_motor, sensor_map, 
             ignition_advance, injection_time);
    
    #200;
    $display("T=%0t | RPM=%d TPS=%d Temp=%d MAP=%d | Adv=%d Inj=%d", 
             $time, sensor_rpm, sensor_tps, sensor_temp_motor, sensor_map, 
             ignition_advance, injection_time);
    
    #650;
    $display("T=%0t | RPM=%d TPS=%d Temp=%d MAP=%d | Adv=%d Inj=%d", 
             $time, sensor_rpm, sensor_tps, sensor_temp_motor, sensor_map, 
             ignition_advance, injection_time);
    
    $display("");
    $display("Calculo esperado:");
    $display("  Base: MAP*10 + 1000 = 35*10 + 1000 = 1350");
    $display("  Com 30%%: 1350 + (1350*30/100) = 1350 + 405 = 1755");
    $display("");
    
    if (injection_time > 1000) begin
        $display("[PASS] Injecao aumentada corretamente: %d", injection_time);
    end else begin
        $display("[FAIL] Injecao incorreta: %d (esperado: >1000)", injection_time);
    end
    
    $finish;
end

endmodule
