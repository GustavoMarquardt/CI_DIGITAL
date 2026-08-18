// Escrita síncrona, leitura assíncrona

module data_memory (
    input clk,
    input [31:0] A, // Endereço 
    input [31:0] WD, // Dado de escrita
    input WE, // Enable de escrita
    output [31:0] RD // Dado de leitura
);

reg [31:0] Memory_cell [0:127]; // 128 unidades de memória de 32 bits
wire [6:0] word_addr;

// Converter byte address para word address
assign word_addr = A[8:2]; // Usa bits 8:2 para endereçar até 128 words

// Inicialização com Lookup Table de Ignição
// Endereço 0x0100 (64) em diante: Tabela 8x8 de avanço de ignição
// Eixo RPM: 1000, 1500, 2000, 2500, 3000, 4000, 5000, 6000
// Eixo TPS: 0%, 14%, 28%, 42%, 56%, 70%, 84%, 100%
// Valores: graus de avanço antes do TDC
initial
begin
    // Constantes para algoritmos de controle (endereços 0-5)
    Memory_cell[0] = 32'd147;  // Lambda estequiométrico * 10 (14.7:1)
    Memory_cell[1] = 32'd125;  // Lambda para potência * 10 (12.5:1)
    Memory_cell[2] = 32'd1000; // Tempo base de injeção (us)
    Memory_cell[3] = 32'd6500; // RPM limite (rev limiter)
    Memory_cell[4] = 32'd120;  // Temperatura limite motor (°C)
    Memory_cell[5] = 32'd60;   // Temperatura para enriquecimento (°C)
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
    
    // Lookup Table de Ignição - 8x8 (endereços 64-127)
    // RPM (linhas): 1000, 1500, 2000, 2500, 3000, 4000, 5000, 6000
    // TPS (colunas): 0%, 14%, 28%, 42%, 56%, 70%, 84%, 100%
    Memory_cell[64] = 32'd10;  Memory_cell[65] = 32'd12;  Memory_cell[66] = 32'd14;  Memory_cell[67] = 32'd16;
    Memory_cell[68] = 32'd18;  Memory_cell[69] = 32'd18;  Memory_cell[70] = 32'd19;  Memory_cell[71] = 32'd20;
    Memory_cell[72] = 32'd11;  Memory_cell[73] = 32'd13;  Memory_cell[74] = 32'd15;  Memory_cell[75] = 32'd18;
    Memory_cell[76] = 32'd19;  Memory_cell[77] = 32'd20;  Memory_cell[78] = 32'd20;  Memory_cell[79] = 32'd21;
    Memory_cell[80] = 32'd13;  Memory_cell[81] = 32'd15;  Memory_cell[82] = 32'd17;  Memory_cell[83] = 32'd19;
    Memory_cell[84] = 32'd21;  Memory_cell[85] = 32'd21;  Memory_cell[86] = 32'd22;  Memory_cell[87] = 32'd23;
    Memory_cell[88] = 32'd14;  Memory_cell[89] = 32'd16;  Memory_cell[90] = 32'd18;  Memory_cell[91] = 32'd21;
    Memory_cell[92] = 32'd22;  Memory_cell[93] = 32'd23;  Memory_cell[94] = 32'd23;  Memory_cell[95] = 32'd24;
    Memory_cell[96] = 32'd16;  Memory_cell[97] = 32'd18;  Memory_cell[98] = 32'd20;  Memory_cell[99] = 32'd22;
    Memory_cell[100] = 32'd24; Memory_cell[101] = 32'd24; Memory_cell[102] = 32'd25; Memory_cell[103] = 32'd26;
    Memory_cell[104] = 32'd19; Memory_cell[105] = 32'd21; Memory_cell[106] = 32'd23; Memory_cell[107] = 32'd25;
    Memory_cell[108] = 32'd27; Memory_cell[109] = 32'd27; Memory_cell[110] = 32'd28; Memory_cell[111] = 32'd29;
    Memory_cell[112] = 32'd22; Memory_cell[113] = 32'd24; Memory_cell[114] = 32'd26; Memory_cell[115] = 32'd28;
    Memory_cell[116] = 32'd30; Memory_cell[117] = 32'd30; Memory_cell[118] = 32'd31; Memory_cell[119] = 32'd32;
    Memory_cell[120] = 32'd25; Memory_cell[121] = 32'd27; Memory_cell[122] = 32'd29; Memory_cell[123] = 32'd31;
    Memory_cell[124] = 32'd33; Memory_cell[125] = 32'd33; Memory_cell[126] = 32'd34; Memory_cell[127] = 32'd35;

end

always @ (posedge clk)
begin
    if(WE)
    begin
        Memory_cell[word_addr] <= WD; // Escreve na unidade de endereço word_addr
    end
end

assign RD = Memory_cell[word_addr]; // Lê da unidade de endereço word_addr

endmodule