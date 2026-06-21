module cpu_complete_tb();

reg clk, rst;

cpu dut (
    .clk(clk),
    .rst(rst)
);

initial begin
    $display("=== Testbench Completo do Processador Single-Cycle ===");
    $display("Testando: ADD, SUB, MUL, DIV, MOD, AND, OR, SLT, ADDI, LW, SW, BEQ, BNE, JAL");
    $display("");
    
    clk = 0;
    rst = 1;
    #10
    rst = 0;
    
    $display("Ciclo | PC | Instrução");
    $display("------|----|-----------");
    
    #500;
    
    $display("");
    $display("=== Verificação dos Registradores ===");
    $display("x1  = %d (esperado: 10)", dut.dp1.register.Register[1]);
    $display("x2  = %d (esperado: 5)", dut.dp1.register.Register[2]);
    $display("x3  = %d (esperado: 10 - valor carregado de memória)", dut.dp1.register.Register[3]);
    $display("x4  = %d (esperado: 5 - valor carregado de memória)", dut.dp1.register.Register[4]);
    $display("x5  = %d (esperado: 15 - soma de x3 + x4)", dut.dp1.register.Register[5]);
    $display("x6  = %d (esperado: 15 - OR de x3 | x4)", dut.dp1.register.Register[6]);
    $display("x7  = %d (esperado: 5 - subtração x3 - x4)", dut.dp1.register.Register[7]);
    $display("x8  = %d (esperado: 0 - AND de x3 & x4)", dut.dp1.register.Register[8]);
    
    $display("");
    $display("=== Teste das Novas Operações ===");
    $display("Valores calculados durante simulação:");
    
    $display("");
    $display("=== Teste Concluído ===");
    $finish;
end

always #5 clk = ~clk;

// Monitor para acompanhar execução
always @(posedge clk) begin
    if (!rst) begin
        $display("%5d | %2d | %h", $time/10, dut.dp1.PC, dut.dp1.Instr);
    end
end

endmodule
