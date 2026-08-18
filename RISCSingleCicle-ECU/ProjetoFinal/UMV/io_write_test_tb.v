module io_write_test_tb();

reg clk, rst;
wire [7:0] ignition_advance;
wire [15:0] injection_time;
wire ignition_trigger;
wire [7:0] safety_flags;

// Sensores fixos para teste
wire [15:0] sensor_rpm = 16'd800;
wire [7:0] sensor_tps = 8'd0;
wire [7:0] sensor_temp_motor = 8'd90;
wire [7:0] sensor_temp_ar = 8'd25;
wire [7:0] sensor_map = 8'd30;
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
    $display("Teste de escrita nos atuadores");
    $display("Sensores: RPM=800, TPS=0, Temp=90C");
    $display("Expectativa: Avanco~10-13, Injecao~1300");
    $display("");
    
    // Reset
    rst = 1;
    #20;
    $display("T=%0t: Apos reset - Adv=%d, Inj=%d, Flags=%b", $time, ignition_advance, injection_time, safety_flags);
    rst = 0;
    
    // Aguardar alguns ciclos
    #50;
    $display("T=%0t: Apos 50ns - Adv=%d, Inj=%d, Flags=%b", $time, ignition_advance, injection_time, safety_flags);
    
    #100;
    $display("T=%0t: Apos 150ns - Adv=%d, Inj=%d, Flags=%b", $time, ignition_advance, injection_time, safety_flags);
    
    #200;
    $display("T=%0t: Apos 350ns - Adv=%d, Inj=%d, Flags=%b", $time, ignition_advance, injection_time, safety_flags);
    
    #500;
    $display("T=%0t: Apos 850ns - Adv=%d, Inj=%d, Flags=%b", $time, ignition_advance, injection_time, safety_flags);
    
    $display("");
    if (ignition_advance != 15 || injection_time != 1000) begin
        $display("[SUCESSO] CPU conseguiu escrever nos atuadores!");
        $display("Valores: Adv=%d, Inj=%d", ignition_advance, injection_time);
    end else begin
        $display("[FALHA] CPU NAO conseguiu escrever nos atuadores");
        $display("Valores permanecem no default: Adv=15, Inj=1000");
        $display("PROBLEMA: CPU nao esta executando ou I/O nao esta funcionando");
    end
    
    $finish;
end

endmodule
