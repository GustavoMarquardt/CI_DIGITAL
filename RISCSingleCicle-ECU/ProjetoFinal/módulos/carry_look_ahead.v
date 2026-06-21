module carry_look_ahead #(parameter N = 4) (
    input  [N-1:0] A,     //! Entrada A (4 bits)
    input  [N-1:0] B,     //! Entrada B (4 bits)
    input        C_in,  //! Carry inicial
    output [N-1:0] S,     //! Soma final (4 bits)
    output       C_out  //! Carry final
);
integer i;

    // Sinais intermediários para Carry-Generate (G) e Carry-Propagate (P)
    wire [N-1:0] G;  //! Carry-Generate
    wire [N-1:0] P;  //! Carry-Propagate
    reg [N:0] C;  //! Carry intermediário (C[0] = C_in, C[4] = C_out)

    // Associar o Carry de entrada
    

    // Calcular G e P
    assign G = A & B;   // G_i = A_i AND B_i
    assign P = A | B;   // P_i = A_i OR B_i

    // Calcular os carries intermediários
    always @(*) begin
        C[0] = C_in;
        for (i = 0; i < N ; i = i + 1 ) begin
            C[i + 1] = G[i] | (P[i] & C[i]);
        end
    end
     

    // Calcular a soma
    assign S = A ^ B ^ C[N-1:0];  // S_i = A_i XOR B_i XOR C_i

    // Associar o Carry final
    assign C_out = C[N];

endmodule
