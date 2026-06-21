module datapath2_tb();
reg [31:0] SignImm;
reg [31:0] WriteData;
reg [31:0] SrcA;
reg [2:0] ALUControl;
reg MemWrite;
reg MemtoReg;
reg clk;
reg ALUSrc;
wire zero;
wire [31:0] Result;

datapath2 uut (
    .SignImm(SignImm),
    .WriteData(WriteData),
    .SrcA(SrcA),
    .ALUControl(ALUControl),
    .MemWrite(MemWrite),
    .MemtoReg(MemtoReg),
    .clk(clk),
    .ALUSrc(ALUSrc),
    .zero(zero),
    .Result(Result)
);

initial
begin
    clk = 0;
    ALUControl = 3'b010;
    WriteData = 32'h00000002;
    SignImm = 32'h00000002; // Example immediate value
    SrcA = 32'h00000002; // Example source A value
    #2;
    MemWrite = 1;
    #8;
    MemWrite = 0; // Disable memory write for the next operations


    // Initialize inputs
    SignImm = 32'hFFFF0000;
    SrcA = 32'h0000FFFF;
    WriteData = 32'h0000FFFF;
    ALUControl = 3'b010; // Example ALU control signal
    MemWrite = 0;
    MemtoReg = 0;
 
    ALUSrc = 0;

    #10;
    ALUControl = 3'b110;
    #10;
    ALUControl = 3'b000;
    #10;
    ALUControl = 3'b001;
    #10;
    ALUControl = 3'b111;
    #10;

    ALUSrc = 1;
    #10;
    ALUControl = 3'b010; 
    MemWrite = 1;
    #10;
    MemWrite = 0;
    MemtoReg = 1;
    ALUControl = 3'b110;
    #10;
    ALUControl = 3'b000;
    #10;
    ALUControl = 3'b001;
    #10;
    ALUControl = 3'b111;
    #10;
    ALUControl = 3'b010;
    WriteData = 32'h00000002;
    SrcA = 32'h00000002; // Example source A value
    SignImm = 32'h00000002; 
    



    #10 $finish; // End simulation
end

always #5 clk = ~clk; // Clock generation
endmodule