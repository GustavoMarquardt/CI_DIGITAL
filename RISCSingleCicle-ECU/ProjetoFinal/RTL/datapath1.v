module datapath1 (
    input clk, rst,
    input [31:0] PCTarget, PCPlus4, // entradas do mux do PC
    input [31:0] Result, // Valor da saída do mux com data memory e ALU
    input PCSrc, // Sinal do módulo controlador PCSrc
    input RegWrite, // Sinal do módulo controlador RegWrite
    output [31:0] PC,
    output [31:0] Instr,
    output [31:0] WriteData,
    output [31:0] SrcA
);
    wire [31:0] next_PC;
    
mux2x1_32bits mux (
    .inA(PCPlus4),
    .inB(PCTarget),
    .sel(PCSrc),
    .out(next_PC)
);

PC pc(
    .rst(rst),
    .clk(clk),
    .next_PC(next_PC),
    .PC(PC)
);

instruction_memory im (
    .A(PC),
    .RD(Instr)
);

register_file rf (
    .clk(clk),
    .A1(Instr[19:15]),
    .A2(Instr[24:20]),
    .A3(Instr[11:7]),
    .WD3(Result),
    .RD1(SrcA),
    .RD2(WriteData),
    .WE(RegWrite)
);

endmodule

//Datapath azul da imagem de ref.
