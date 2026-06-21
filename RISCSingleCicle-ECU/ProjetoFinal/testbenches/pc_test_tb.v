module pc_test_tb();

reg clk, rst;
wire [31:0] PC;
wire [31:0] Instr;
wire [7:0] ignition_advance;
wire [15:0] injection_time;
wire ignition_trigger;
wire [7:0] safety_flags;

// Sensores fixos
wire [15:0] sensor_rpm = 16'd800;
wire [7:0] sensor_tps = 8'd50;
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

// Conectar sinais internos para depuração
assign PC = ecu.dp1.PC;
assign Instr = ecu.dp1.Instr;

// Clock generation
initial clk = 0;
always #5 clk = ~clk;

initial begin
    $display("Teste do PC");
    $display("");
    
    // Reset
    rst = 1;
    #10;
    $display("T=10 (rst=1): PC=%h, Instr=%h", PC, Instr);
    
    rst = 0;
    #10;
    $display("T=20 (rst=0): PC=%h, Instr=%h", PC, Instr);
    
    #10;
    $display("T=30: PC=%h, Instr=%h", PC, Instr);
    
    #10;
    $display("T=40: PC=%h, Instr=%h", PC, Instr);
    
    #10;
    $display("T=50: PC=%h, Instr=%h", PC, Instr);
    
    #10;
    $display("T=60: PC=%h, Instr=%h", PC, Instr);
    
    #50;
    $display("T=110: PC=%h, Instr=%h", PC, Instr);
    $display("");
    $display("Saídas: Advance=%d, Injection=%d", ignition_advance, injection_time);
    
    $finish;
end

endmodule
