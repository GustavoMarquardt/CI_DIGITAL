module instruction_memory_tb();

    // Entradas
    reg [31:0] A;  // Endereço de leitura

    // Saídas
    wire [31:0] RD;  // Dados lidos

    // Instanciar o módulo sob teste (UUT)
    instruction_memory uut (
        .A(A),
        .RD(RD)
    );

    // Teste de leitura de memória
    initial begin
        // Inicializando variáveis
        A = 32'h00000000;  // Endereço inicial (0)
        
        // Monitorando a saída
        $display("Iniciando simulação de leitura de memória");
        $monitor("Tempo=%0dns | Endereço=%h | Instrução lida=%h", $time, A, RD);

        // Esperar 10ns antes de iniciar os testes
        #10;

        // Teste 1: Leitura do endereço 0x0000
        A = 32'h00000000;
        #10;  // Esperar 10ns para estabilizar

        // Teste 2: Leitura do endereço 0x0004
        A = 32'h00000004;
        #10;

        // Teste 3: Leitura do endereço 0x0008
        A = 32'h00000008;
        #10;

        // Teste 4: Leitura do endereço 0x000C
        A = 32'h0000000C;
        #10;

        // Teste 5: Leitura do endereço 0x0010
        A = 32'h00000010;
        #10;

        // Teste 6: Leitura do endereço 0x0014
        A = 32'h00000014;
        #10;

        // Teste 7: Leitura do endereço 0x0018
        A = 32'h00000018;
        #10;

        // Teste 8: Leitura do endereço 0x0020
        A = 32'h00000020;
        #10;

        // Teste 9: Leitura do endereço 0x0030
        A = 32'h00000030;
        #10;

        A = 32'h1000;
        #10;

        // Finalizar simulação
        $finish;
    end
endmodule
