module Main_Decoder (
    input [6:0] op,
    output reg Branch,
    output reg [1:0] ResultSrc,
    output reg MemWrite,
    output reg ALUSrc,
    output reg [1:0] ImmSrc,
    output reg RegWrite,
    output reg [1:0] ALUOp
    output reg Jump;
    );

always @ (*)
begin
    casex (op)
        7'b0000011: begin //lw
            RegWrite = 1;
            ImmSrc = 2'b00;
            ALUSrc = 1;
            MemWrite = 0;
            ResultSrc = 2'b01;
            Branch = 0;
            ALUOp = 2'b00;
            Jump = 1'b0;
        end
        7'b0100011: begin //sw
            RegWrite = 0;
            ImmSrc = 2'b01;
            ALUSrc = 1;
            MemWrite = 1;
            ResultSrc = 2'bx;
            Branch = 0;
            ALUOp = 2'b00;
            Jump = 1'b0;
        end
        7'b0110011: begin //r-type
            RegWrite = 1;
            ImmSrc = 2'bxx;
            ALUSrc = 0;
            MemWrite = 0;
            ResultSrc = 2'b00;
            Branch = 0;
            ALUOp = 2'b10;
            Jump = 1'b0;
        end
        7'b1100011: begin //beq
            RegWrite = 0;
            ImmSrc = 2'b10;
            ALUSrc = 0;
            MemWrite = 0;
            ResultSrc = 2'bxx;
            Branch = 1;
            ALUOp = 2'b01;
            Jump = 1'b0;
        end
        7'b0010011: begin // I-type
            RegWrite = 1'b1;
            ImmSrc = 2'b00; // Immediate source
            ALUSrc = 1'b1; // ALU source is immediate
            MemWrite = 1'b0; // No memory write
            ResultSrc = 2'b00; // Result comes from ALU
            Branch = 0; // No branching
            ALUOp = 2'b10; // ALU operation for I-type instructions
            Jump = 1'b0;
        end
        7'b1101111: begin
            RegWrite = 1;
            ImmSrc = 2'b11; // JAL
            ALUSrc = 0;
            MemWrite = 0;
            ResultSrc = 2'b10;
            Branch = 0;
            ALUOp = 2'bxx; // JAL não usa ALU, mas é necessário definir um valor
            Jump = 1'b1;
        end 
        default: begin
            RegWrite = 0;
            ImmSrc = 2'bxx;
            ALUSrc = 0;
            MemWrite = 0;
            ResultSrc = 1'bx;
            Branch = 0;
            ALUOp = 2'b00;
            Jump = 1'b0;
        end
    endcase
end
endmodule
/*module Main_Decoder (
    input [5:0] Opcode,
    output reg [1:0] ULAOp,
    output reg MemtoReg,
    output reg MemWrite,
    output reg Branch,
    output reg ULASrc,
    output reg RegDst,
    output reg RegWrite
);

always @(*) begin
    case (Opcode)
        6'b000000 : begin
            RegWrite = 1;
            RegDst = 1;
            ULASrc = 0;
            Branch = 0;
            MemWrite = 0;
            MemtoReg = 0;
            ULAOp = 10;
        end 
        6'b100011 : begin
            RegWrite = 1;
            RegDst = 0;
            ULASrc = 1;
            Branch = 0;
            MemWrite = 0;
            MemtoReg = 1;
            ULAOp = 00; 
        end
        6'b101011 : begin
            RegWrite =0;
            RegDst = 0;
            ULASrc = 1;
            Branch = 0;
            MemWrite = 1;
            MemtoReg = 0;
            ULAOp = 00; 
        end
        6'b000100 : begin
            RegWrite = 0;
            RegDst = 0;
            ULASrc = 0;
            Branch = 1;
            MemWrite = 0;
            MemtoReg = 0;
            ULAOp = 01; 
        end
        default: begin
            RegWrite = 0;
            RegDst = 0;
            ULASrc = 0;
            Branch = 0;
            MemWrite = 0;
            MemtoReg = 0;
            ULAOp = 00; 
        end           

    endcase
end
    
endmodule*/
