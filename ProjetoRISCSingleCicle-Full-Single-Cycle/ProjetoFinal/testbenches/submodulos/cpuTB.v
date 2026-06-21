module cpuTB();

reg clk, rst;

cpu dut (
    .clk(clk),
    .rst(rst)
);

initial
begin
    clk = 0;
    rst = 1;
    #10
    rst = 0;
    #500 $finish;
end

always #5 clk = ~clk;
endmodule