module cpu(
input clk, rst,

// Sinais dos sensores (entradas)
input [15:0] sensor_rpm,
input [7:0] sensor_tps,
input [7:0] sensor_temp_motor,
input [7:0] sensor_temp_ar,
input [7:0] sensor_map,
input sensor_tdc,

// Sinais adicionais da TCU (cambio)
input [15:0] vehicle_speed,
input        brake,
input [7:0]  drive_mode,

// Sinais dos atuadores (saídas)
output [7:0] ignition_advance,
output [15:0] injection_time,
output ignition_trigger,
output [7:0] safety_flags
);

wire PCSrc, MemWrite, ALUSrc, RegWrite;
wire [1:0] ResultSrc;
wire [1:0] ImmSrc;
wire [2:0] ALUControl;

wire zero, negative;
wire [31:0] Instr, PCTarget, PCPlus4, Result, PC, WriteData, SrcA;

wire [31:0] ImmExt;

Control_Unit control (
  .op(Instr[6:0]),
  .zero(zero),
  .negative(negative),
  .PCSrc(PCSrc),
  .ResultSrc(ResultSrc),
  .MemWrite(MemWrite),
  .ALUSrc(ALUSrc),
  .ImmSrc(ImmSrc),
  .RegWrite(RegWrite),
  .funct3(Instr[14:12]),
  .funct7({Instr[30], Instr[25]}),
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
  .rst(rst),
  .ALUSrc(ALUSrc),
  .sensor_rpm(sensor_rpm),
  .sensor_tps(sensor_tps),
  .sensor_temp_motor(sensor_temp_motor),
  .sensor_temp_ar(sensor_temp_ar),
  .sensor_map(sensor_map),
  .sensor_tdc(sensor_tdc),
  .vehicle_speed(vehicle_speed),
  .brake(brake),
  .drive_mode(drive_mode),
  .ignition_advance(ignition_advance),
  .injection_time(injection_time),
  .ignition_trigger(ignition_trigger),
  .safety_flags(safety_flags),
  .zero(zero),
  .negative(negative),
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
