module Main_Decoder_tb ();

    reg [5:0] Opcode;
    wire [1:0] ULAOp;
    wire MemtoReg;
    wire MemWrite;
    wire Branch;
    wire ULASrc;
    wire RegDst;
    wire RegWrite;

    // Instância do módulo Main_Decoder
    Main_Decoder uut (
        .Opcode(Opcode),
        .ULAOp(ULAOp),
        .MemtoReg(MemtoReg),
        .MemWrite(MemWrite),
        .Branch(Branch),
        .ULASrc(ULASrc),
        .RegDst(RegDst),
        .RegWrite(RegWrite)
    );

    initial begin
        // Teste com diferentes OpCodes
        Opcode = 6'b000000; // R-type
        #10;
        
        Opcode = 6'b100011; // LW
        #10;

        Opcode = 6'b101011; // SW
        #10;

        Opcode = 6'b000100; // BEQ
        #10;
        Opcode = 6'b001000; // BEQ
        #10;

        $finish; // Finaliza a simulação
    end

    
endmodule
