module shifter(
    input [31:0] shift_src,
    input [4:0] shift_amt,
    input [2:0] shift_op,
    output [31:0] shift_res
);
wire op_sll = (shift_op == 3'h4) ? 1'b1 : 1'b0;
wire op_srl = (shift_op == 3'h2) ? 1'b1 : 1'b0;
wire op_sra = (shift_op == 3'h1) ? 1'b1 : 1'b0;

wire [31:0] shift_rev_src;
wire [31:0] shift_res_sll;
wire [31:0] shift_res_srl;
wire [31:0] shift_res_sra;
wire [31:0] shift_temp_res;
wire [31:0] shift_mask;

assign shift_rev_src = op_sll ? {shift_src[ 0],shift_src[ 1],shift_src[ 2],shift_src[ 3],
                                 shift_src[ 4],shift_src[ 5],shift_src[ 6],shift_src[ 7],
                                 shift_src[ 8],shift_src[ 9],shift_src[10],shift_src[11],
                                 shift_src[12],shift_src[13],shift_src[14],shift_src[15],
                                 shift_src[16],shift_src[17],shift_src[18],shift_src[19],
                                 shift_src[20],shift_src[21],shift_src[22],shift_src[23],
                                 shift_src[24],shift_src[25],shift_src[26],shift_src[27],
                                 shift_src[28],shift_src[29],shift_src[30],shift_src[31]} : shift_src;
assign shift_temp_res = shift_rev_src >> shift_amt[4:0];
assign shift_res_srl  = shift_temp_res;
assign shift_mask     = ~(32'hffffffff >> shift_amt[4:0]);
assign shift_res_sra  = ({32{shift_rev_src[31]}} & shift_mask) | shift_temp_res;
assign shift_res_sll  = {shift_temp_res[ 0],shift_temp_res[ 1],shift_temp_res[ 2],shift_temp_res[ 3],
                         shift_temp_res[ 4],shift_temp_res[ 5],shift_temp_res[ 6],shift_temp_res[ 7],
                         shift_temp_res[ 8],shift_temp_res[ 9],shift_temp_res[10],shift_temp_res[11],
                         shift_temp_res[12],shift_temp_res[13],shift_temp_res[14],shift_temp_res[15],
                         shift_temp_res[16],shift_temp_res[17],shift_temp_res[18],shift_temp_res[19],
                         shift_temp_res[20],shift_temp_res[21],shift_temp_res[22],shift_temp_res[23],
                         shift_temp_res[24],shift_temp_res[25],shift_temp_res[26],shift_temp_res[27],
                         shift_temp_res[28],shift_temp_res[29],shift_temp_res[30],shift_temp_res[31]};

assign shift_res      = op_sll ? shift_res_sll :
                        op_srl ? shift_res_srl :
                        op_sra ? shift_res_sra : 32'b0;

endmodule
