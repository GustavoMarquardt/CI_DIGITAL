module carry_look_ahead_tb;

    parameter N = 32;

    reg [N-1:0] A, B;
    reg C_in;
    wire [N-1:0] S;
    wire C_out;

    // Instancia o DUT
    carry_look_ahead #(N) dut (
        .A(A),
        .B(B),
        .C_in(C_in),
        .S(S),
        .C_out(C_out)
    );

    initial begin
        $display("Time\t\tA\t\t\t\tB\t\t\t\tC_in\tS\t\t\t\tC_out");

        // Teste 1: Soma simples sem carry-in
        A = 32'h0000_0001;
        B = 32'h0000_0001;
        C_in = 0;
        #10;
        $display("%0t\t%h\t%h\t%b\t%h\t%b", $time, A, B, C_in, S, C_out);

        // Teste 2: Soma simples com carry-in
        A = 32'h0000_0001;
        B = 32'h0000_0001;
        C_in = 1;
        #10;
        $display("%0t\t%h\t%h\t%b\t%h\t%b", $time, A, B, C_in, S, C_out);

        // Teste 3: Overflow (maior valor possível)
        A = 32'hFFFF_FFFF;
        B = 32'h0000_0001;
        C_in = 0;
        #10;
        $display("%0t\t%h\t%h\t%b\t%h\t%b", $time, A, B, C_in, S, C_out);

        // Teste 4: Soma de dois valores grandes
        A = 32'hFFFF_0000;
        B = 32'h0000_FFFF;
        C_in = 1;
        #10;
        $display("%0t\t%h\t%h\t%b\t%h\t%b", $time, A, B, C_in, S, C_out);

        // Teste 5: Caso aleatório
        A = 32'h1234_5678;
        B = 32'h8765_4321;
        C_in = 0;
        #10;
        $display("%0t\t%h\t%h\t%b\t%h\t%b", $time, A, B, C_in, S, C_out);

        // Teste 6: Caso aleatório com carry-in
        A = 32'h0F0F_0F0F;
        B = 32'hF0F0_F0F0;
        C_in = 1;
        #10;
        $display("%0t\t%h\t%h\t%b\t%h\t%b", $time, A, B, C_in, S, C_out);

        $display("Fim dos testes.");
        $finish;
    end

endmodule
