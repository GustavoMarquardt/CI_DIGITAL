
module datapath1_tb();

    // Entradas
    reg clk, rst;
    reg [31:0] PCTarget, PCPlus4;
    reg [31:0] Result;
    reg PCSrc;
    reg RegWrite;

    // Saídas
    wire [31:0] PC;
    wire [31:0] Instr;
    wire [31:0] WriteData;
    wire [31:0] SrcA;

    // Instanciar o módulo sob teste (UUT)
    datapath1 uut (
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

    // Clock: 10ns período (100 MHz)
    always #5 clk = ~clk;

    initial begin

        // Inicializações
        clk = 0;
        rst = 1;
        
        PCTarget = 32'h00000000;
        PCPlus4 = PC + 4;
        Result = 32'hABCD1234; // Valor a ser escrito em um registrador
        PCSrc = 0;
        RegWrite = 0;

        // Esperar 1 ciclo de clock com reset ativo
        #10;
        rst = 0;

        // Teste 1: Avanço normal de PC (PCPlus4), sem escrita
        PCSrc = 0;       // Seleciona PCPlus4
        PCPlus4 = PC + 4;
        RegWrite = 0;    // Não escreve no banco de registradores
        #10;

        // Teste 2: Mudança de fluxo com PCSrc = 1
        PCSrc = 1;       // Seleciona PCTarget
        PCTarget = 32'h00000010;
        #10;

        // Teste 3: Habilita escrita no registrador de destino
        RegWrite = 1;
        Result = 32'hDEADBEEF;
        #10;

        // Teste 4: Nova instrução, escrita habilitada
        PCSrc = 0;
        PCPlus4 = PC + 4;
        Result = 32'hCAFEBABE;
        #10;

        // Finalizar simulação
        $finish;
    end

endmodule
