module mux3x1_32bits(
    input [31:0] inA, inB, inC,
    input [1:0] sel,
    output reg [31:0] out
);

always @ (*)
begin
    case(sel)
    2'b00 : out = inA;
    2'b01 : out = inB;
    2'b10 : out = inC;
    default : out = 2'bxx;
    endcase
end

endmodule
