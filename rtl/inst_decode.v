`include "mycpu.h"

module inst_decode(
    // 来自指令的字段
    input  wire [31:0] ds_inst,

    // Decoder输出
    input  wire [63:0] op_31_26_d,
    input  wire [15:0] op_25_22_d,
    input  wire [ 3:0] op_21_20_d,
    input  wire [31:0] op_19_15_d,

    // 指令译码总线输出
    output wire [`INST_BUS_WD-1:0] inst_bus
);

// ============== Internal signals
wire inst_add_w;
wire inst_sub_w;
wire inst_slt;
wire inst_sltu;
wire inst_nor;
wire inst_and;
wire inst_or;
wire inst_xor;
wire inst_slli_w;
wire inst_srli_w;
wire inst_srai_w;
wire inst_addi_w;
wire inst_ld_w;
wire inst_st_w;
wire inst_jirl;
wire inst_b;
wire inst_bl;
wire inst_beq;
wire inst_bne;
wire inst_lu12i_w;
wire inst_slti;
wire inst_sltui;
wire inst_andi;
wire inst_ori;
wire inst_xori;
wire inst_sllw;
wire inst_srlw;
wire inst_sraw;
wire inst_pcaddu12i;
wire inst_mulw;
wire inst_mulhw;
wire inst_mulhwu;
wire inst_div;
wire inst_modw;
wire inst_divu;
wire inst_modwu;
wire inst_blt;
wire inst_bge;
wire inst_bltu;
wire inst_bgeu;
wire inst_ldb;
wire inst_ldh;
wire inst_ldbu;
wire inst_ldhu;
wire inst_stb;
wire inst_sth;

// ==============decode instruction
assign inst_add_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
assign inst_sub_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
assign inst_slt    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
assign inst_sltu   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];
assign inst_nor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
assign inst_and    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
assign inst_or     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
assign inst_xor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];
assign inst_slli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];
assign inst_srli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];
assign inst_srai_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
assign inst_addi_w = op_31_26_d[6'h00] & op_25_22_d[4'ha];
assign inst_ld_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
assign inst_st_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h6];
assign inst_jirl   = op_31_26_d[6'h13];
assign inst_b      = op_31_26_d[6'h14];
assign inst_bl     = op_31_26_d[6'h15];
assign inst_beq    = op_31_26_d[6'h16];
assign inst_bne    = op_31_26_d[6'h17];
assign inst_lu12i_w= op_31_26_d[6'h05] & ~ds_inst[25];
assign inst_slti   = op_31_26_d[6'h00] & op_25_22_d[4'h8];
assign inst_sltui  = op_31_26_d[6'h00] & op_25_22_d[4'h9];
assign inst_andi   = op_31_26_d[6'h00] & op_25_22_d[4'hd];
assign inst_ori    = op_31_26_d[6'h00] & op_25_22_d[4'he];
assign inst_xori   = op_31_26_d[6'h00] & op_25_22_d[4'hf];
assign inst_sllw   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0e];
assign inst_srlw   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0f];
assign inst_sraw   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h10];
assign inst_pcaddu12i = op_31_26_d[6'h07] & ~ds_inst[25];
assign inst_mulw    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h18];
assign inst_mulhw   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h19];
assign inst_mulhwu  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h1a];
assign inst_div     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h00];
assign inst_modw    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h01];
assign inst_divu    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h02];
assign inst_modwu   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h03];
assign inst_blt     = op_31_26_d[6'h18];
assign inst_bge     = op_31_26_d[6'h19];
assign inst_bltu    = op_31_26_d[6'h1a];
assign inst_bgeu    = op_31_26_d[6'h1b];
assign inst_ldb     = op_31_26_d[6'h0a] & op_25_22_d[4'h0];
assign inst_ldh     = op_31_26_d[6'h0a] & op_25_22_d[4'h1];
assign inst_ldbu    = op_31_26_d[6'h0a] & op_25_22_d[4'h8];
assign inst_ldhu    = op_31_26_d[6'h0a] & op_25_22_d[4'h9];
assign inst_stb     = op_31_26_d[6'h0a] & op_25_22_d[4'h4];
assign inst_sth     = op_31_26_d[6'h0a] & op_25_22_d[4'h5];

// ============== Pack inst_bus
// Bit mapping:
// [41]: inst_add_w     [40]: inst_sub_w     [39]: inst_slt
// [38]: inst_sltu      [37]: inst_nor       [36]: inst_and
// [35]: inst_or        [34]: inst_xor       [33]: inst_slli_w
// [32]: inst_srli_w    [31]: inst_srai_w    [30]: inst_addi_w
// [29]: inst_ld_w      [28]: inst_st_w      [27]: inst_jirl
// [26]: inst_b         [25]: inst_bl        [24]: inst_beq
// [23]: inst_bne       [22]: inst_lu12i_w   [21]: inst_slti
// [20]: inst_sltui     [19]: inst_andi      [18]: inst_ori
// [17]: inst_xori      [16]: inst_sllw      [15]: inst_srlw
// [14]: inst_sraw      [13]: inst_pcaddu12i [12]: inst_mulw
// [11]: inst_mulhw     [10]: inst_mulhwu    [9]:  inst_div
// [8]:  inst_modw      [7]:  inst_divu      [6]:  inst_modwu
// [5]:  inst_blt       [4]:  inst_bge       [3]:  inst_bltu
// [2]:  inst_bgeu      [1]:  inst_ldb       [0]:  inst_ldh
// Extended: inst_ldbu, inst_ldhu, inst_stb, inst_sth

assign inst_bus = {
    inst_add_w,      // 45
    inst_sub_w,      // 44
    inst_slt,        // 43
    inst_sltu,       // 42
    inst_nor,        // 41
    inst_and,        // 40
    inst_or,         // 39
    inst_xor,        // 38
    inst_slli_w,     // 37
    inst_srli_w,     // 36
    inst_srai_w,     // 35
    inst_addi_w,     // 34
    inst_ld_w,       // 33
    inst_st_w,       // 32
    inst_jirl,       // 31
    inst_b,          // 30
    inst_bl,         // 29
    inst_beq,        // 28
    inst_bne,        // 27
    inst_lu12i_w,    // 26
    inst_slti,       // 25
    inst_sltui,      // 24
    inst_andi,       // 23
    inst_ori,        // 22
    inst_xori,       // 21
    inst_sllw,       // 20
    inst_srlw,       // 19
    inst_sraw,       // 18
    inst_pcaddu12i,  // 17
    inst_mulw,       // 16
    inst_mulhw,      // 15
    inst_mulhwu,     // 14
    inst_div,        // 13
    inst_modw,       // 12
    inst_divu,       // 11
    inst_modwu,      // 10
    inst_blt,        // 9
    inst_bge,        // 8
    inst_bltu,       // 7
    inst_bgeu,       // 6
    inst_ldb,        // 5
    inst_ldh,        // 4
    inst_ldbu,       // 3
    inst_ldhu,       // 2
    inst_stb,        // 1
    inst_sth         // 0
};

endmodule
