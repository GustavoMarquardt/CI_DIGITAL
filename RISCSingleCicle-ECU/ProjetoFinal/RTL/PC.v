module PC (
    input clk, rst,
    input [31:0] next_PC,
    output reg [31:0] PC
);

always @ (posedge clk or posedge rst)
begin
    if(rst) PC <= 32'h0; else
    PC <= next_PC;
end
endmodule