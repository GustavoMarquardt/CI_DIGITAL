// Escrita síncrona, leitura assíncrona
//completo, precisa de mais testes para confirmar
module register_file (
    input [4:0] A1, A2, A3, //! Endereços
    input [31:0] WD3, // Dados de entrada
    input WE, // Enable
    output reg [31:0] RD1, RD2, // Leitura dos dados
    input clk
);

reg [31:0] register [0:31]; // 32 registradores de 32 bits

initial
begin
    register[0] = 32'h0;
    register[1] = 32'h0;
    register[2] = 32'h0;
    register[3] = 32'h0;
    register[4] = 32'h4;
    register[5] = 32'h0;
    register[6] = 32'h0;
    register[7] = 32'h0;
    register[8] = 32'h0;
    register[9] = 32'h0;
    register[10] = 32'h0;
    register[11] = 32'h0;
    register[12] = 32'h0;
    register[13] = 32'h0;
    register[14] = 32'h0;
    register[15] = 32'h0;
    register[16] = 32'h0;
    register[17] = 32'h0;
    register[18] = 32'h0;
    register[19] = 32'h0;
    register[20] = 32'h0;
    register[21] = 32'h0;
    register[22] = 32'h0;
    register[23] = 32'h0;
    register[24] = 32'h0;
    register[25] = 32'h0;
    register[26] = 32'h0;
    register[27] = 32'h0;
    register[28] = 32'h0;
    register[29] = 32'h0;
    register[30] = 32'h0;
    register[31] = 32'h0;


end

always @ (posedge clk)
begin
    if (WE && A3 != 5'd0)
        register[A3] <= WD3;
end

always @ (*)
begin
    RD1 = (A1 == 5'd0) ? 32'd0 : register[A1];
    RD2 = (A2 == 5'd0) ? 32'd0 : register[A2];
end
endmodule