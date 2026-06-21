module ALU(
    input [31:0] A, B,
    input [2:0] ALUControl,
    output reg [31:0] ALUResult,
    output reg Zero,
    output Negative
);

assign Negative = ALUResult[31];

always @(*)
begin
    case (ALUControl)
        3'b000: ALUResult = A + B; //soma
        3'b001: ALUResult = A - B; //sub
        3'b010: ALUResult = A & B; //and
        3'b011: ALUResult = A | B; //or
        3'b100: ALUResult = A * B; //mul
        3'b101: ALUResult = (A < B) ? 32'd1 : 32'd0; //slt
        3'b110: ALUResult = (B != 0) ? (A / B) : 32'hFFFFFFFF; //div (proteção divisão por zero)
        3'b111: ALUResult = (B != 0) ? (A % B) : 32'h0; //mod (proteção divisão por zero)
        default: ALUResult = 32'b0; 
    endcase
end

always @(*)
begin
    if (ALUResult == 32'b0) begin
        Zero = 1'b1;
    end
    else Zero = 1'b0;
end


endmodule
