module desloca_tb;

    reg [31:0] Signlmm;
    wire [31:0] desloca_out;

    // Instancia o DUT
    desloca dut (
        .Signlmm(Signlmm),
        .desloca(desloca_out)
    );

    initial begin
        $display("Time\t\tSignlmm\t\t\tDesloca");

        // Teste 1: Valor pequeno
        Signlmm = 32'h0000_0001;
        #10;
        $display("%0t\t%h\t%h", $time, Signlmm, desloca_out);

        // Teste 2: Valor com 1 no bit 30
        Signlmm = 32'h4000_0000;
        #10;
        $display("%0t\t%h\t%h", $time, Signlmm, desloca_out);

        // Teste 3: Valor máximo
        Signlmm = 32'hFFFF_FFFF;
        #10;
        $display("%0t\t%h\t%h", $time, Signlmm, desloca_out);

        // Teste 4: Valor aleatório
        Signlmm = 32'h1234_5678;
        #10;
        $display("%0t\t%h\t%h", $time, Signlmm, desloca_out);

        // Teste 5: Valor aleatório 2
        Signlmm = 32'h8765_4321;
        #10;
        $display("%0t\t%h\t%h", $time, Signlmm, desloca_out);

        $display("Fim dos testes.");
        $finish;
    end

endmodule
