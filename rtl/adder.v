module adder(
    input [31:0] adder_src1,
    input [31:0] adder_src2,
    input adder_cin ,
    output [31:0] adder_result,
    output adder_cout,
    output adder_of   // signed overflow
);

    wire [32:0] temp_result = {1'b0, adder_src1} + {1'b0, adder_src2} + adder_cin;

    assign adder_result = temp_result[31:0];
    assign adder_cout   = temp_result[32];
    
    assign adder_of = (adder_src1[31] == adder_src2[31]) && 
                      (adder_result[31] != adder_src1[31]);
endmodule
