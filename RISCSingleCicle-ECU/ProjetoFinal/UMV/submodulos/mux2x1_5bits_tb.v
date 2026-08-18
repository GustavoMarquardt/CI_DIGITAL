module mux2x1_5bits_tb();
reg [4:0] inA, inB;
reg sel;
wire [4:0] out;

mux2x1_5bits dut (
    .inA(inA),
    .inB(inB),
    .sel(sel),
    .out(out)
);

initial
begin
    inA = 5'b10101;
    inB = 5'b00000;
    sel = 0;
    #10;
    sel = 1;
    #10;
end

endmodule
