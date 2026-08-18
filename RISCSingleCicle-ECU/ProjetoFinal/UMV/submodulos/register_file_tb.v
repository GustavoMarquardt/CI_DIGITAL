module register_file_tb ();
    reg [4:0] A1, A2, A3;
    reg [31:0] WD3;
    reg WE;
    reg clk;
    wire [31:0] RD1, RD2;

register_file dut (
    .clk(clk),
    .A1(A1),
    .A2(A2),
    .A3(A3),
    .WD3(WD3),
    .WE(WE),
    .RD1(RD1),
    .RD2(RD2)
);

initial
begin
    clk = 0;
    A1 = 0;
    A2 = 1;
    WD3 = 0;
    A3 = 0;
    WE = 0;

    #5 WE = 1;
    #5 A3 = 1;
    #5 A3 = 31;
    #5 WD3 = 32'd5890;
    #5 WE = 0;
    
    #5 A2 = 31;
    #5 $finish;
end

always #2 clk = ~clk;

endmodule