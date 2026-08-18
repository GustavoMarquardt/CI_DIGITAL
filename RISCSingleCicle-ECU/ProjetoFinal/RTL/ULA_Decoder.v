module ULA_Decoder (
    input [1:0] ALUOp,
    input op,
    input [2:0] funct3,
    input [1:0] funct7, // {Instr[30], Instr[25]}
    output reg [2:0] ALUControl
);

wire [7:0] aux;
assign aux = {ALUOp, funct3, op, funct7};

always @(*)
begin
    casex (aux)
        8'b00??????: ALUControl = 3'b000; // LW/SW
        8'b01??????: ALUControl = 3'b001; // branches
        8'b100000??: ALUControl = 3'b000; // ADDI
        8'b100100??: ALUControl = 3'b101; // SLTI
        8'b101100??: ALUControl = 3'b011; // ORI
        8'b101110??: ALUControl = 3'b010; // ANDI
        8'b10000100: ALUControl = 3'b000; // ADD
        8'b10000110: ALUControl = 3'b001; // SUB
        8'b10000101: ALUControl = 3'b100; // MUL
        8'b10100101: ALUControl = 3'b110; // DIV
        8'b10101101: ALUControl = 3'b110; // DIVU
        8'b10110101: ALUControl = 3'b111; // REM
        8'b10111101: ALUControl = 3'b111; // REMU
        8'b10010100: ALUControl = 3'b101; // SLT
        8'b10110100: ALUControl = 3'b011; // OR
        8'b10111100: ALUControl = 3'b010; // AND
        default:     ALUControl = 3'b000;
    endcase
end

endmodule
