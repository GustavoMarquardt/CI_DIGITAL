module PC_IM();
    reg [31:0] PC; // Program Counter
    wire [31:0] instruction; // Instrução lida da memória de instruções

    // Instância do módulo de memória de instruções
    instruction_memory IM (
        .A(PC), // Endereço do PC
        .RD(instruction) // Dado lido
    );

    initial begin
        PC = 32'h00000000; // Inicializa o PC com zero
    end

always
begin
    #4; // Atraso de 4 unidades de tempo
    PC = PC + 4; // Incrementa o PC para a próxima instrução
    #4;
    PC = PC + 4; // Incrementa novamente o PC para a próxima instrução
    #4;
    PC = PC + 4; // Incrementa mais uma vez o PC para a próxima instrução
    #4;
    PC = PC + 4; // Incrementa mais uma vez o PC para a próxima instrução
    #4;
    PC = PC + 4; // Incrementa mais uma vez o PC para a próxima instrução
    #4;
    $finish;
end
endmodule