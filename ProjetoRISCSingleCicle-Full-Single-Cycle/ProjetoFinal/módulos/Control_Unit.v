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
  input funct7,
  output [2:0] ALUControl
);

wire Branch;
wire Jump;
wire [1:0] ALUOp;
assign PCSrc = (Branch & zero) | Jump;
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
