module SignExtend_TB;

    reg [15:0] in;
    wire [31:0] out;

    SignExtend sign_extend (
        .in(in),
        .out(out)
    );

    initial begin
        // Test case 1: Positive number
        in = 16'b0000000000000001;
        #10;
        
        
        // Test case 2: Negative number
        in = 16'b1000000000000001;
        #10;
        
        $finish;
    end
endmodule