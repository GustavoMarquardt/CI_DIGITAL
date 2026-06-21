module instruction_memory (
    input [31:0] A, // Endereço
    output reg [31:0] RD // Barramento de elitura de dados
);

reg [31:0] instruction [0:63]; // 32 espaços de instrução de 32 bits cada
wire [29:0] aux;
assign aux = A [31:2];

//espaços de memória para teste inicial    
initial begin

    instruction[0] = 32'b000000001010_00000_000_00001_0010011;  //addi x1, x0, 10 
    instruction[1] = 32'b000000000101_00000_000_00010_0010011;  //addi x2, x0, 5
    instruction[2] = 32'b0000000_00001_00001_010_00000_0100011; //sw x1, 0(x1) 
    instruction[3] = 32'b0000000_00010_00010_010_00000_0100011; //sw x2, 0(x2)
    instruction[4] = 32'b000000000000_00001_010_00011_0000011;  //lw x3, 0(x1) 
    instruction[5] = 32'b000000000000_00010_010_00100_0000011;  //lw x4, 0(x2)
    instruction[6] = 32'b0000000_00011_00100_000_00101_0110011; //add x5, x3, x4
    instruction[7] = 32'b0000000_00011_00100_110_00110_0110011; //or x6, x3, x4
    instruction[8] = 32'b0100000_00100_00100_110_00111_0110011; //sub x7, x3, x4
    instruction[9] = 32'b0000000_00100_00011_111_01000_0110011; //and x8, x3, x4

    instruction[10] = 32'b0000000_10100_00000_000_01010_0010011; //addi x10, x0, 20
    instruction[11] = 32'b0000000_00001_00000_000_00011_0010011; //addi x3, x0, 1
    instruction[12] = 32'b0000000_00011_00001_000_00001_0110011; //add x1, x1, x3
    instruction[13] = 32'b0010100_01010_00001_000_10100_1100011; //beq x1, x10, 20
    instruction[14] = 32'b1111111_10101_11111_111_01001_1101111; // jal x9, -12

                             
end
always @ (*)
begin
    RD = instruction[aux]; // Saída recebe a instrução alinhada
end
endmodule