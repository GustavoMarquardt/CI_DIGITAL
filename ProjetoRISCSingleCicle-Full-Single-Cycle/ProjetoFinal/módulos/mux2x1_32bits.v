module mux2x1_32bits(
    input [31:0] inA, inB,
    input sel,
    output [31:0] out
);

assign out = (sel == 1) ? inB : inA;

endmodule
