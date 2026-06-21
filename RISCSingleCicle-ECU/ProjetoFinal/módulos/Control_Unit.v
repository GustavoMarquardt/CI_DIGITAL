module Control_Unit (
  input [6:0] op,
  output [1:0]ResultSrc,
  output MemWrite,
  output PCSrc,
  output ALUSrc,
  output [1:0] ImmSrc,
  output RegWrite,
  input [2:0] funct3,
  input zero,
  input negative,
  input [1:0] funct7,
  output [2:0] ALUControl
);

wire Branch;
wire Jump;
wire [1:0] ALUOp;

reg branch_condition;
always @(*) begin
    case (funct3)
        3'b000: branch_condition = zero;                 // BEQ: rs1 == rs2
        3'b001: branch_condition = ~zero;                // BNE: rs1 != rs2
        3'b100: branch_condition = negative & ~zero;     // BLT: rs1 < rs2 (signed, negative and not zero)
        3'b101: branch_condition = ~negative | zero;     // BGE: rs1 >= rs2 (signed, positive or zero)
        default: branch_condition = 1'b0;
    endcase
end

assign PCSrc = (Branch & branch_condition) | Jump;
Main_Decoder maindecoder (
  .op(op),
  .Branch(Branch),
  .ResultSrc(ResultSrc),
  .MemWrite(MemWrite),
  .ALUSrc(ALUSrc),
  .ImmSrc(ImmSrc),
  .RegWrite(RegWrite),
  .ALUOp(ALUOp),
  .Jump(Jump)
);

ULA_Decoder uladecoder (
  .ALUOp(ALUOp),
  .op(op[5]),
  .funct3(funct3),
  .funct7(funct7),
  .ALUControl(ALUControl)
);

endmodule
/*module Control_Unit (
  input [5:0] Opcode,
  input [5:0] Funct,
  output MemtoReg,
  output MemWrite,
  output Branch,
  output ULASrc,
  output RegDst,
  output RegWrite,
  output ALUControl
);

wire [1:0] ALUOp;
  
Main_Decoder maindecoder (
  .Opcode(Opcode),
  .ULAOp(ALUOp),
  .MemtoReg(MemtoReg),
  .MemWrite(MemWrite),
  .Branch(Branch),
  .ULASrc(ULASrc),
  .RegDst(RegDst),
  .RegWrite(RegWrite)
);

ULA_Decoder uladecoder (
  .Funct(Funct),
  .ALUOp(ALUOp),
  .ULAControl(ALUControl)
);

endmodule*/
