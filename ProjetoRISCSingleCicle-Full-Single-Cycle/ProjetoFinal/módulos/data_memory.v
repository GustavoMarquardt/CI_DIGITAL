// Escrita síncrona, leitura assíncrona

module data_memory (
    input clk,
    input [31:0] A, // Endereço 
    input [31:0] WD, // Dado de escrita
    output WE, // Enable de escrita
    output [31:0] RD // Dado de leitura
);

reg [31:0] Memory_cell [0:63]; // 32 unidades de memória de 32 bits

/*initial
begin
    Memory_cell[0] = 32'h0;
    Memory_cell[1] = 32'h0;
    Memory_cell[2] = 32'h0;
    Memory_cell[3] = 32'h0;
    Memory_cell[4] = 32'h0;
    Memory_cell[5] = 32'h0;
    Memory_cell[6] = 32'h0;
    Memory_cell[7] = 32'h0;
    Memory_cell[8] = 32'h0;
    Memory_cell[9] = 32'h0;
    Memory_cell[10] = 32'h0;
    Memory_cell[11] = 32'h0;
    Memory_cell[12] = 32'h0;
    Memory_cell[13] = 32'h0;
    Memory_cell[14] = 32'h0;
    Memory_cell[15] = 32'h0;
    Memory_cell[16] = 32'h0;
    Memory_cell[17] = 32'h0;
    Memory_cell[18] = 32'h0;
    Memory_cell[19] = 32'h0;
    Memory_cell[20] = 32'h0;
    Memory_cell[21] = 32'h0;
    Memory_cell[22] = 32'h0;
    Memory_cell[23] = 32'h0;
    Memory_cell[24] = 32'h0;
    Memory_cell[25] = 32'h0;
    Memory_cell[26] = 32'h0;
    Memory_cell[27] = 32'h0;
    Memory_cell[28] = 32'h0;
    Memory_cell[29] = 32'h0;
    Memory_cell[30] = 32'h0;
    Memory_cell[31] = 32'h0;
    Memory_cell[32] = 32'h0;
    Memory_cell[33] = 32'h0;
    Memory_cell[34] = 32'h0;
    Memory_cell[35] = 32'h0;
    Memory_cell[36] = 32'h0;
    Memory_cell[37] = 32'h0;
    Memory_cell[38] = 32'h0;
    Memory_cell[39] = 32'h0;
    Memory_cell[40] = 32'h0;
    Memory_cell[41] = 32'h0;
    Memory_cell[42] = 32'h0;
    Memory_cell[43] = 32'h0;
    Memory_cell[44] = 32'h0;
    Memory_cell[45] = 32'h0;
    Memory_cell[46] = 32'h0;
    Memory_cell[47] = 32'h0;
    Memory_cell[48] = 32'h0;
    Memory_cell[49] = 32'h0;
    Memory_cell[50] = 32'h0;
    Memory_cell[51] = 32'h0;
    Memory_cell[52] = 32'h0;
    Memory_cell[53] = 32'h0;
    Memory_cell[54] = 32'h0;
    Memory_cell[55] = 32'h0;
    Memory_cell[56] = 32'h0;
    Memory_cell[57] = 32'h0;
    Memory_cell[58] = 32'h0;
    Memory_cell[59] = 32'h0;
    Memory_cell[60] = 32'h0;
    Memory_cell[61] = 32'h0;
    Memory_cell[62] = 32'h0;
    Memory_cell[63] = 32'h0;

end*/

always @ (posedge clk)
begin
    if(WE)
    begin
        Memory_cell[A] <= WD; // Escreve na unidade de endereço A
    end
end

assign RD = Memory_cell[A]; // Lê da unidade de endereço A

endmodule