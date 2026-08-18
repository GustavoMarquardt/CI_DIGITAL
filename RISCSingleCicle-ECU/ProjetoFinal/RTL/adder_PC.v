module adder(
    input [31:0] A, B,
    output [31:0] S
);

assign B = 4;
assign S = A + B;

endmodule
