module datapath2 (
  input [31:0] ImmExt,
  input [31:0] WriteData,
  input [31:0] SrcA,
  input [31:0] PCPlus4,
  input [2:0] ALUControl,
  input MemWrite,
  input [1:0] ResultSrc,
  input clk,
  input rst,
  input ALUSrc,
  
  // Sinais dos sensores
  input [15:0] sensor_rpm,
  input [7:0] sensor_tps,
  input [7:0] sensor_temp_motor,
  input [7:0] sensor_temp_ar,
  input [7:0] sensor_map,
  input sensor_tdc,
  
  // Sinais dos atuadores
  output [7:0] ignition_advance,
  output [15:0] injection_time,
  output ignition_trigger,
  output [7:0] safety_flags,
  
  output zero,
  output negative,
  output [31:0] Result
);

  wire [31:0] SrcB;
  wire [31:0] ALUResult;
  wire [31:0] ReadData;
  wire [31:0] ReadData_IO;
  wire [31:0] ReadData_Mem;
  wire io_select;
  wire mem_write_enable;
  wire io_write_enable;
  
  // I/O memory-mapped só a partir de 0x1000 (sensores/atuadores). 0x0100–0x0FF é RAM de dados (lookup).
  assign io_select = (ALUResult >= 32'h00001000);
  assign mem_write_enable = MemWrite & ~io_select;
  assign io_write_enable = MemWrite & io_select;
  
  // Multiplexador para selecionar fonte de leitura
  assign ReadData = io_select ? ReadData_IO : ReadData_Mem;
  
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
    .Zero(zero),
    .Negative(negative)
  );

  data_memory dmemory (
    .clk(clk),
    .A(ALUResult),
    .WD(WriteData),
    .WE(mem_write_enable),
    .RD(ReadData_Mem)
  );
  
  io_controller io (
    .clk(clk),
    .rst(rst),
    .address(ALUResult),
    .write_data(WriteData),
    .write_enable(io_write_enable),
    .read_data(ReadData_IO),
    .sensor_rpm(sensor_rpm),
    .sensor_tps(sensor_tps),
    .sensor_temp_motor(sensor_temp_motor),
    .sensor_temp_ar(sensor_temp_ar),
    .sensor_map(sensor_map),
    .sensor_tdc(sensor_tdc),
    .ignition_advance(ignition_advance),
    .injection_time(injection_time),
    .ignition_trigger(ignition_trigger),
    .safety_flags(safety_flags)
  );

  mux3x1_32bits muxout (
    .inA(ALUResult),
    .inB(ReadData),
    .inC(PCPlus4),
    .sel(ResultSrc),
    .out(Result)
  );

endmodule
