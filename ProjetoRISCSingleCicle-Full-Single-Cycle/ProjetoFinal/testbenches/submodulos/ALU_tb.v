module ULA_tb;

  // Entradas
  reg [31:0] A, B;
  reg [2:0] ALUControl;

  // Saídas
  wire [31:0] ALUResult;
  wire Zero;

  // Instancia a ALU
  ULA dut (
    .A(A),
    .B(B),
    .ALUControl(ALUControl),
    .ALUResult(ALUResult),
    .Zero(Zero)
  );

  // Procedimento de teste
  initial begin

    
    // Teste 1: Soma
    A = 32'd10; B = 32'd5; ALUControl = 3'b000;
    #10;
    // Teste 2: Subtração
    A = 32'd15; B = 32'd15; ALUControl = 3'b001;
    #10;


    // Teste 3: AND
    A = 32'hFF00FF00; B = 32'h0F0F0F0F; ALUControl = 3'b010;
    #10;


    // Teste 4: OR
    A = 32'h0000FFFF; B = 32'hFFFF0000; ALUControl = 3'b011;
    #10;


    // Teste 5: SLT (A < B)
    A = 32'd7; B = 32'd20; ALUControl = 3'b101;
    #10;


    // Teste 6: SLT (A >= B)
    A = 32'd25; B = 32'd10; ALUControl = 3'b101;
    #10;

    // Teste 7: Default
    A = 32'd100; B = 32'd50; ALUControl = 3'b100; // não definido
    #10;

    $stop;
  end

endmodule
