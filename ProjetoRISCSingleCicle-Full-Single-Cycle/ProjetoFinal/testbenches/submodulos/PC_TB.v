//complete
module PC_TB();

reg clk;
reg [31:0] PC_in;
wire [31:0] PC_out;
PC dut (
    .clk(clk),
    .next_PC(PC_in),
    .PC(PC_out)
);
initial begin
    clk = 0;
    PC_in = 32'd0;

    // Test different PC inputs
    #10 PC_in = 32'd4; // Set PC to 4
    #10 PC_in = 32'd8; // Set PC to 8
    #10 PC_in = 32'd12; // Set PC to 12

    // Finish the simulation
    #10 $finish;
end
always #5 clk = ~clk;
endmodule