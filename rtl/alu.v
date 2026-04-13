module alu(
    input [31:0]alu_src1,
    input [31:0]alu_src2,
    input [15:0] alu_op,
    output [31:0] alu_result
);
wire is_addw;
wire is_addiw;
wire is_subw;
wire is_slt; 
wire is_sltu;

wire is_and;
wire is_or;
wire is_nor;
wire is_xor;
wire is_logic;

wire [31:0] adder_src1;
wire [31:0] adder_src2;
wire adder_cin;
wire [31:0] adder_result;
wire adder_cout;
wire adder_of; // signed overflow


assign is_addw  = (alu_op == 16'h01) ? 1'b1 : 1'b0;
assign is_addiw = (alu_op == 16'h02) ? 1'b1 : 1'b0;
assign is_subw  = (alu_op == 16'h04) ? 1'b1 : 1'b0;
assign is_slt   = (alu_op == 16'h08) ? 1'b1 : 1'b0;
assign is_sltu  = (alu_op == 16'h10) ? 1'b1 : 1'b0;

assign is_and   = (alu_op == 16'h100)? 1'b1 : 1'b0;
assign is_or    = (alu_op == 16'h80) ? 1'b1 : 1'b0;
assign is_nor   = (alu_op == 16'h40) ? 1'b1 : 1'b0;
assign is_xor   = (alu_op == 16'h20) ? 1'b1 : 1'b0;
assign is_logic = (is_and | is_or | is_nor | is_xor);



assign adder_src1 = alu_src1;
assign adder_src2 = (is_subw | is_slt | is_sltu ) ? (~alu_src2) : alu_src2;
assign adder_cin  = (is_subw | is_slt | is_sltu ) ? 1'b1 : 1'b0;

adder u_adder(
    .adder_src1(adder_src1),
    .adder_src2(adder_src2),
    .adder_cin(adder_cin),
    .adder_result(adder_result),
    .adder_cout(adder_cout),
    .adder_of(adder_of)
);


wire [31:0] logic_result = is_and ?  (alu_src1 & alu_src2) :
                           is_or  ?  (alu_src1 | alu_src2) :
                           is_nor ? ~(alu_src1 | alu_src2) :
                           is_xor ?  (alu_src1 ^ alu_src2) :
                                     32'b0;

assign alu_result = is_slt  ? {31'b0, (adder_result[31] ^ adder_of)} :
                    is_sltu ? {31'b0, (!adder_cout)} : // 无符号：没进位即借位，A < B
                    is_logic ? logic_result :
                               adder_result;


endmodule
