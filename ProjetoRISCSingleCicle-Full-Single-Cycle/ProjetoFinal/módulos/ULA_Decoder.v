module ULA_Decoder (
    input [1:0] ALUOp,
    input op,
    input [2:0] funct3,
    input funct7,
    output reg [2:0] ALUControl
);

wire [6:0] aux;
assign aux = {ALUOp, funct3, op, funct7};

always @ (*)
begin
casex (aux)
    7'b00_xxx_xx : ALUControl = 3'b000;
    7'b01_xxx_xx : ALUControl = 3'b001;
    7'b10_000_00 : ALUControl = 3'b000;
    7'b10_000_01 : ALUControl = 3'b000;
    7'b10_000_10 : ALUControl = 3'b000;
    7'b10_000_11 : ALUControl = 3'b001;
    7'b10_010_xx : ALUControl = 3'b101;
    7'b10_110_xx : ALUControl = 3'b011;
    7'b10_111_xx : ALUControl = 3'b010;
    default: ALUControl = 3'b000; // Default case to avoid latches
endcase    
end

endmodule
/*module ULA_Decoder (
    input [5:0] Funct,
    input [1:0] ALUOp,
    output reg [2:0] ULAControl
);


always @(*) begin
    casex (ALUOp)
        2'b00 : ULAControl = 3'b010; //add
        2'bx1 : ULAControl = 3'b110; //subtract
        2'b1x : begin
            case (Funct)
                6'b100000 : ULAControl = 3'b010; //add
                6'b100010 : ULAControl = 3'b110; //subtract 
                6'b100100 : ULAControl = 3'b000; //and
                6'b100101 : ULAControl = 3'b001; //or 
                6'b101010 : ULAControl = 3'b111; //set less than 
                default: ULAControl = 6'b0;
            endcase
        end 
        default: ULAControl = 6'b0;
    endcase
end
    
endmodule*/
