module adder_tb();
    reg [31:0] A;
    wire [31:0] S;

adder dut (
    .A(A),
    .S(S)
);

initial
begin
    A = 0;
    # 10;
    A = 32'b0000000000000000000000000000011;
    #10;
    A = 32'b0000000000000010000000000100011;
    #10;
    $finish;
end
endmodule
