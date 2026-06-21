module cpu(
input clk, rst
);

wire PCSrc, MemWrite, ALUSrc, RegWrite;
wire [1:0] ResultSrc;
wire [1:0] ImmSrc;
wire [2:0] ALUControl;

wire zero;
wire [31:0] Instr, PCTarget, PCPlus4, Result, PC, WriteData, SrcA;

wire [31:0] ImmExt;

Control_Unit control (
  .op(Instr[6:0]),
  .zero(zero),
  .PCSrc(PCSrc),
  .ResultSrc(ResultSrc),
  .MemWrite(MemWrite),
  .ALUSrc(ALUSrc),
  .ImmSrc(ImmSrc),
  .RegWrite(RegWrite),
  .funct3(Instr[14:12]),
  .funct7(Instr[30]),
  .ALUControl(ALUControl)
);

datapath1 dp1 (
  .clk(clk),
  .rst(rst),
  .PCTarget(PCTarget),
  .PCPlus4(PCPlus4),
  .Result(Result),
  .PCSrc(PCSrc),
  .RegWrite(RegWrite),
  .PC(PC),
  .Instr(Instr),
  .WriteData(WriteData),
  .SrcA(SrcA)
);

datapath2 dp2 (
  .ImmExt(ImmExt),
  .WriteData(WriteData),
  .SrcA(SrcA),
  .ALUControl(ALUControl),
  .MemWrite(MemWrite),
  .ResultSrc(ResultSrc),
  .PCPlus4(PCPlus4),
  .clk(clk),
  .ALUSrc(ALUSrc),
  .zero(zero),
  .Result(Result)
);

datapath3 dp3 (
  .PC(PC),
  .Instr(Instr[31:7]),
  .ImmSrc(ImmSrc),
  .PCTarget(PCTarget),
  .PCPlus4(PCPlus4),
  .ImmExt(ImmExt)
);
endmodule
