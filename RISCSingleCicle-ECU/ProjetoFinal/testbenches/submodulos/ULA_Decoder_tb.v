module ULA_Decoder_tb ();
    
    reg [1:0] ALUOp;
    reg op;
    reg [2:0] funct3;
    reg funct7;
    wire [2:0] ALUControl;

    ULA_Decoder uut (
        .ALUOp(ALUOp),
        .op(op),
        .funct3(funct3),
        .funct7(funct7),
        .ALUControl(ALUControl)
    );

    initial begin
        // Test cases
        ALUOp = 2'b00; op = 1'b0; funct3 = 3'b000; funct7 = 1'b0; #10; // Expected ALUControl = 3'b000
        ALUOp = 2'b01; op = 1'b0; funct3 = 3'b000; funct7 = 1'b0; #10; // Expected ALUControl = 3'b001
        ALUOp = 2'b10; op = 1'b0; funct3 = 3'b000; funct7 = 1'b0; #10; // Expected ALUControl = 3'b000
        ALUOp = 2'b10; op = 1'b0; funct3 = 3'b001; funct7 = 1'b0; #10; // Expected ALUControl = 3'b001
        ALUOp = 2'b10; op = 1'b0; funct3 = 3'b010; funct7 = 1'b0; #10; // Expected ALUControl = 3'b101
        ALUOp = 2'b10; op = 1'b0; funct3 = 3'b110; funct7 = 1'b0; #10; // Expected ALUControl = 3'b011
        ALUOp = 2'b10; op = 1'b0; funct3 = 3'b111; funct7 = 1'b0; #10; // Expected ALUControl = 3'b010

        $finish;
    end

endmodule
