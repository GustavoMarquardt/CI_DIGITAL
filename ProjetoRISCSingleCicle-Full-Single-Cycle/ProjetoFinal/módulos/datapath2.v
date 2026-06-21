module datapath2 (
  input [31:0] ImmExt,
  input [31:0] WriteData,
  input [31:0] SrcA,
  input [31:0] PCPlus4;
  input [2:0] ALUControl,
  input MemWrite,
  input [1:0] ResultSrc,
  input clk,
  input ALUSrc,
  output zero,
  output [31:0] Result
);

  wire [31:0] SrcB;
  wire [31:0] ALUResult;
  wire [31:0] ReadData;
  
  mux2x1_32bits muxin (
    .inA(WriteData),
    .inB(ImmExt),
    .sel(ALUSrc),
    .out(SrcB)
  );

  ALU alu (
    .A(SrcA),
    .B(SrcB),
    .ALUControl(ALUControl),
    .ALUResult(ALUResult),
    .Zero(zero)
  );

  data_memory dmemory (
    .clk(clk),
    .A(ALUResult),
    .WD(WriteData),
    .WE(MemWrite),
    .RD(ReadData)
  );

  mux3x1_32bits muxout (
    .inA(ALUResult),
    .inB(ReadData),
    .inC(PCPlus4),
    .sel(ResultSrc),
    .out(Result)
  );

endmodule
