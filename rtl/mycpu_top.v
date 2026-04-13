module mycpu_top(
    input  wire        clk,
    input  wire        resetn,

    output wire        inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,

    output wire        data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,

     // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata,
    output wire [31:0] debug_wb_rf_inst
);

reg         reset = 1'b1;
always @(posedge clk) reset <= ~resetn;

reg         valid = 1'b0;
always @(posedge clk) begin
    if (reset) begin
        valid <= 1'b0;
    end
    else begin
        valid <= 1'b1;
    end
end

reg  [31:0] pc;
wire [31:0] nextpc;

// Initialize pc for simulation

   
wire [31:0] inst;

wire [ 5:0] op_31_26;
wire [ 3:0] op_25_22;
wire [ 1:0] op_21_20;
wire [ 4:0] op_19_15;
wire [63:0] op_31_26_d;
wire [15:0] op_25_22_d;
wire [ 3:0] op_21_20_d;
wire [31:0] op_19_15_d;
wire [ 4:0] rd;
wire [ 4:0] rj;
wire [ 4:0] rk;
wire [11:0] i12;
wire [15:0] i16;
wire [19:0] i20;
wire [25:0] i26;

wire        inst_add_w;
wire        inst_addi_w;

wire        inst_ld_w;
wire        inst_st_w;

wire        inst_bne;
wire        inst_beq;
wire        inst_b;


wire        inst_sub_w;
wire        inst_slt;
wire        inst_sltu;
wire        inst_slliw;
wire        inst_srliw;
wire        inst_sraiw;

wire        inst_and;
wire        inst_or;
wire        inst_nor;
wire        inst_xor;

wire        inst_lu12i;

wire        src2_is_imm;
wire        res_from_mem;
wire        gr_we;
wire        mem_we;
wire        src_reg_is_rd;

wire [31:0] rj_value;
wire [31:0] rkd_value;

wire [ 4:0] rf_raddr1;
wire [ 4:0] rf_raddr2;
wire [ 4:0] rf_waddr;
wire [31:0] rf_wdata;

wire [4: 0] dest;

wire [31:0] imm16;
wire [31:0] imm26;
wire        br_taken;
wire        rj_eq_rd;
wire [31:0] br_offs;
wire [31:0] jirl_offs;
wire [31:0] br_target;
wire        sel_br_offs;

// =================submodule

wire [31:0] imm;
wire [31:0] alu_src1;
wire [31:0] alu_src2;
wire [31:0] alu_result;
wire [15:0]  alu_op;

wire [31:0] shift_src;
wire [4:0]  shift_amt;
wire [2:0]  shift_op;
wire [31:0] shift_res;

// ===================

wire is_alu;
wire is_shifter;

always @(posedge clk) begin
    if (reset) begin
        pc <= 32'h1bfffffc;     //trick: to make nextpc be 0x1c000000 during reset 
    end
    else begin
        pc <= nextpc;
    end
end

assign inst_sram_we    = 1'b0;
assign inst_sram_addr  = pc;
assign inst_sram_wdata = 32'b0;
assign inst            = inst_sram_rdata;

assign op_31_26 = inst[31:26];
assign op_25_22 = inst[25:22];
assign op_21_20 = inst[21:20];
assign op_19_15 = inst[19:15];
assign rd       = inst[4: 0];
assign rj       = inst[ 9: 5];
assign rk       = inst[14:10];
assign i12      = inst[21:10];
assign i16      = inst[25:10];
assign i20  = inst[24: 5];
assign i26  = {inst[ 9: 0], inst[25:10]};

decoder_6_64 u_dec0(.in(op_31_26 ), .co(op_31_26_d ));
decoder_4_16 u_dec1(.in(op_25_22 ), .co(op_25_22_d ));
decoder_2_4  u_dec2(.in(op_21_20 ), .co(op_21_20_d ));
decoder_5_32 u_dec3(.in(op_19_15 ), .co(op_19_15_d ));

assign inst_add_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
assign inst_addi_w = op_31_26_d[6'h00] & op_25_22_d[4'ha];

assign inst_ld_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
assign inst_st_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h6];

assign inst_bne    = op_31_26_d[6'h17];
assign inst_beq    = op_31_26_d[6'h16];
assign inst_b      = op_31_26_d[6'h14];
assign inst_bl     = op_31_26_d[6'h15];
assign inst_jirl   = op_31_26_d[6'h13];


assign inst_sub_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
assign inst_slt    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
assign inst_sltu   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];

assign inst_slliw  = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];
assign inst_srliw  = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];
assign inst_sraiw  = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];

assign inst_and    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
assign inst_or     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
assign inst_nor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
assign inst_xor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];

assign inst_lu12i  = op_31_26_d[6'h05] & ~inst[25];





assign src2_is_imm   = inst_addi_w;//在这里实现立即数选择信号
assign gr_we         = inst_add_w | inst_ld_w | inst_addi_w | inst_slliw | inst_slt | inst_sltu | 
                       inst_sraiw | inst_srliw | inst_sub_w | inst_and | inst_or | inst_nor | inst_xor |
                       inst_lu12i | inst_bl | inst_jirl;
assign mem_we        = inst_st_w;
assign src_reg_is_rd = inst_beq | inst_bne | inst_st_w;

assign res_from_mem  = inst_ld_w;

assign rf_raddr1 = rj;
assign rf_raddr2 = src_reg_is_rd ? rd :rk;
assign rf_waddr  = (~inst_bl) ? rd : 1;
regfile u_regfile(
    .clk    (clk      ),
    .raddr1 (rf_raddr1),
    .rdata1 (rj_value),
    .raddr2 (rf_raddr2),
    .rdata2 (rkd_value),
    .we     (gr_we    ),
    .waddr  (rf_waddr ),
    .wdata  (rf_wdata)
    );
assign jirl_offs = {{14{i16[15]}}, i16[15:0], 2'b0};
assign sel_br_offs = (inst_b | inst_bl);
assign br_offs   = sel_br_offs ? {{ 4{i26[25]}}, i26[25:0], 2'b0} : {{14{i16[15]}}, i16[15:0], 2'b0} ;
assign br_target = (inst_beq || inst_bne || inst_bl || inst_b) ? (pc + br_offs) : (rj_value + jirl_offs);
assign rj_eq_rd  = (rj_value == rkd_value);
assign br_taken  = (   inst_beq  &&  rj_eq_rd
                   || inst_bne  && !rj_eq_rd
                   || inst_jirl
                   || inst_bl
                   || inst_b
                  ) && valid;
assign nextpc    = (br_taken) ? br_target : (pc+4);

// ============================submodule

assign imm       = {{20{i12[11]}},i12[11:0]};
assign alu_src1  = rj_value;
assign alu_src2  = (inst_sub_w | inst_add_w | inst_slt | inst_sltu | inst_and | inst_or | inst_nor | inst_xor) ? rkd_value : imm;
// 00000001 addw 00000010 addiw 00000100 sub 00001000 stl 00010000 stlus 0x20 xor 0x40 nor 0x80 or 0x100 and
assign alu_op    = {{7{1'b0}},inst_and,inst_or,inst_nor,inst_xor,inst_sltu,inst_slt,inst_sub_w,inst_addi_w,inst_add_w};

assign shift_src = (~inst_lu12i) ? rj_value : inst[24:5];
assign shift_amt = (inst_slliw | inst_srliw | inst_sraiw ) ? i12[4:0] : 4'hc;
// slli_w 100 srli_w 010 srai_w 001;
assign shift_op  = {inst_slliw,inst_srliw,inst_sraiw};

alu u_alu(
    .alu_src1(alu_src1),
    .alu_src2(alu_src2),
    .alu_op(alu_op),
    .alu_result(alu_result)
);

shifter u_shifter(
    .shift_src(shift_src),
    .shift_amt(shift_amt),
    .shift_op(shift_op),
    .shift_res(shift_res)
);

assign is_alu     = inst_add_w || inst_addi_w || inst_slt || inst_sltu || inst_sub_w || inst_and || inst_or || inst_nor || inst_xor;
assign is_shifter = inst_slliw || inst_srliw || inst_sraiw;

// ============================

assign data_sram_we    = mem_we;
assign data_sram_addr  = alu_result;
assign data_sram_wdata = rkd_value;

assign rf_wdata = is_alu ? alu_result:
                  is_shifter ? shift_res :
                  inst_lu12i ? {i20[19:0], 12'b0}   :
                  (inst_bl | inst_jirl) ? (pc + 4) :
                  res_from_mem ? data_sram_rdata : 32'b0;



assign debug_wb_pc       = pc;
assign debug_wb_rf_we    = {4{gr_we}} & valid;
assign debug_wb_rf_wnum  = rf_waddr;
assign debug_wb_rf_wdata = rf_wdata;

assign debug_wb_rf_inst  = inst_sram_rdata;

endmodule
                         
// 1c0131ec处某个跳转指令有问题 inst = b