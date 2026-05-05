module alu(
  input  wire [27:0] alu_op,
  input  wire [31:0] alu_src1,
  input  wire [31:0] alu_src2,
  input  wire        clk,
  input  wire        reset,
  output wire [31:0] alu_result,
  output wire        stall_divider_s,
  output wire        stall_divider_u,
  output wire        ready_s,
  output wire        ready_u
);

wire op_add;   //add operation
wire op_sub;   //sub operation
wire op_slt;   //signed compared and set less than
wire op_sltu;  //unsigned compared and set less than
wire op_and;   //bitwise and
wire op_nor;   //bitwise nor
wire op_or;    //bitwise or
wire op_xor;   //bitwise xor
wire op_sll;   //logic left shift
wire op_srl;   //logic right shift
wire op_sra;   //arithmetic right shift
wire op_lui;   //Load Upper Immediate
wire op_mulw;  //multiply word
wire op_mulhw; //multiply high word
wire op_mulhwu;//multiply high word unsigned
wire op_div;   //divide

// control code decomposition
assign op_add  = alu_op[ 0] | alu_op[20];
assign op_sub  = alu_op[ 1];
assign op_slt  = alu_op[ 2] | alu_op[12];  //slti
assign op_sltu = alu_op[ 3] | alu_op[13];  //sltiu
assign op_and  = alu_op[ 4] | alu_op[14];  //andi
assign op_nor  = alu_op[ 5];
assign op_or   = alu_op[ 6] | alu_op[15];  //ori
assign op_xor  = alu_op[ 7] | alu_op[16];  //xori
assign op_sll  = alu_op[ 8] | alu_op[17];  //sllw
assign op_srl  = alu_op[ 9] | alu_op[18];  //srlw
assign op_sra  = alu_op[10] | alu_op[19];  //sraw
assign op_lui  = alu_op[11];
assign op_mulw = alu_op[21];
assign op_mulhw = alu_op[22];
assign op_mulhwu = alu_op[23];
assign op_div  = alu_op[24];
assign op_modw = alu_op[25];
assign op_divu = alu_op[26];
assign op_modwu = alu_op[27];


wire [31:0] add_sub_result;
wire [31:0] slt_result;
wire [31:0] sltu_result;
wire [31:0] and_result;
wire [31:0] nor_result;
wire [31:0] or_result;
wire [31:0] xor_result;
wire [31:0] lui_result;
wire [31:0] sll_result;
wire [63:0] sr64_result;
wire [31:0] sr_result;
wire [63:0] mul_result;
wire [63:0] mulu_result;
wire [31:0] mulw_result;
wire [31:0] mulhw_result;
wire [31:0] mulhwu_result;
wire [31:0] div_quotient_s;
wire [31:0] div_remainder_s;
wire        stall_divider_s_wire;
wire        ready_s_wire;
wire [31:0] div_quotient_u;
wire [31:0] div_remainder_u;
wire        stall_divider_u_wire;
wire        ready_u_wire;

reg [31:0] div_result_s_reg;
reg [31:0] div_result_u_reg;
reg [31:0] div_remainder_s_reg;
reg [31:0] div_remainder_u_reg;
reg        ready_s_d, ready_u_d;

// 生成单周期脉冲的en信号
reg        op_div_d, op_divu_d;
wire       div_en_pulse_s;
wire       div_en_pulse_u;

always @(posedge clk) begin
    if (reset) begin
        op_div_d <= 1'b0;
        op_divu_d <= 1'b0;
    end
    else begin
        op_div_d <= op_div | op_modw;
        op_divu_d <= op_divu | op_modwu;
    end
end

// 只在操作码从0变1时产生单周期脉冲
assign div_en_pulse_s = (op_div | op_modw) & ~op_div_d;
assign div_en_pulse_u = (op_divu | op_modwu) & ~op_divu_d;

always @(posedge clk) begin
    if (reset) begin
        div_result_s_reg <= 32'b0;
        div_result_u_reg <= 32'b0;
        div_remainder_s_reg <= 32'b0;
        div_remainder_u_reg <= 32'b0;
        ready_s_d <= 1'b0;
        ready_u_d <= 1'b0;
    end
    else begin
        if (ready_s_wire) begin
            div_result_s_reg <= div_quotient_s;
            div_remainder_s_reg <= div_remainder_s;
        end
        if (ready_u_wire) begin
            div_result_u_reg <= div_quotient_u;
            div_remainder_u_reg <= div_remainder_u;
        end
        ready_s_d <= ready_s_wire;
        ready_u_d <= ready_u_wire;
    end
end

wire [31:0] div_src1;
wire [31:0] div_src2;

// 32-bit adder
wire [31:0] adder_a;
wire [31:0] adder_b;
wire        adder_cin;
wire [31:0] adder_result;
wire        adder_cout;

assign adder_a   = alu_src1;
assign adder_b   = (op_sub | op_slt | op_sltu ) ? ~alu_src2 : alu_src2;  //src1 - src2 rj-rk
assign adder_cin = (op_sub | op_slt | op_sltu ) ? 1'b1      : 1'b0;
assign {adder_cout, adder_result} = adder_a + adder_b + adder_cin;

// ADD, SUB result
assign add_sub_result = adder_result;

// SLT result
assign slt_result[31:1] = 31'b0;   //rj < rk 1
assign slt_result[0]    = (alu_src1[31] & ~alu_src2[31])
                        | ((alu_src1[31] ~^ alu_src2[31]) & adder_result[31]);

// SLTU result
assign sltu_result[31:1] = 31'b0;
assign sltu_result[0]    = ~adder_cout;

// bitwise operation
assign and_result = alu_src1 & alu_src2;
assign or_result  = alu_src1 | alu_src2;
assign nor_result = ~or_result;
assign xor_result = alu_src1 ^ alu_src2;
assign lui_result = alu_src2;

// SLL result
assign sll_result = alu_src1 << alu_src2[4:0];   //rj << ui5

// SRL, SRA result
assign sr64_result = {{32{op_sra & alu_src1[31]}}, alu_src1[31:0]} >> alu_src2[4:0]; //rj >> i5

assign div_src1  = alu_src1;
assign div_src2  = alu_src2;
assign sr_result   = sr64_result[31:0];
assign mul_result  = $signed(alu_src1) * $signed(alu_src2);
assign mulu_result = $unsigned(alu_src1) * $unsigned(alu_src2);
assign mulw_result = mul_result[31:0];
assign mulhw_result = mul_result[63:32];
assign mulhwu_result = mulu_result[63:32];

divider u_divider_signed(
    .clk(clk),
    .rstn(~reset),
    .dividend(div_src1),
    .divisor(div_src2),
    .en(div_en_pulse_s),
    .flush_exception(1'b0),
    .sign(1'b1),
    .quotient(div_quotient_s),
    .remainder(div_remainder_s),
    .stall_divider(stall_divider_s_wire),
    .ready(ready_s_wire)
);

divider u_divider_unsigned(
    .clk(clk),
    .rstn(~reset),
    .dividend(div_src1),
    .divisor(div_src2),
    .en(div_en_pulse_u),
    .flush_exception(1'b0),
    .sign(1'b0),
    .quotient(div_quotient_u),
    .remainder(div_remainder_u),
    .stall_divider(stall_divider_u_wire),
    .ready(ready_u_wire)
);

assign stall_divider_s = stall_divider_s_wire;
assign stall_divider_u = stall_divider_u_wire;
assign ready_s = ready_s_wire;
assign ready_u = ready_u_wire;
// final result mux
assign alu_result = ({32{op_add|op_sub }} & add_sub_result)
                  | ({32{op_slt        }} & slt_result)
                  | ({32{op_sltu       }} & sltu_result)
                  | ({32{op_and       }} & and_result)
                  | ({32{op_nor       }} & nor_result)
                  | ({32{op_or        }} & or_result)
                  | ({32{op_xor       }} & xor_result)
                  | ({32{op_lui       }} & lui_result)
                  | ({32{op_sll       }} & sll_result)
                  | ({32{op_srl|op_sra}} & sr_result)
                  | ({32{op_mulw      }} & mulw_result)
                  | ({32{op_mulhw     }} & mulhw_result)
                  | ({32{op_mulhwu    }} & mulhwu_result)
                  | ({32{op_div }}   & div_result_s_reg)
                  | ({32{op_divu }}   & div_result_u_reg)
                  | ({32{op_modw }}   & div_remainder_s_reg)
                  | ({32{op_modwu}}  & div_remainder_u_reg);

endmodule
