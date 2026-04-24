`include "mycpu.h"

module controller(
    // 指令译码总线输入
    input  wire [`INST_BUS_WD-1:0] inst_bus,
    
    // 控制信号输出
    output wire src_reg_is_rd,
    output wire src1_is_pc,
    output wire src2_is_imm,
    output wire res_from_mem,
    output wire dst_is_r1,
    output wire gr_we,
    output wire mem_we
);

// ============== Unpack inst_bus
// Bit mapping (must match inst_decode.v)
wire inst_beq        = inst_bus[28];
wire inst_bne        = inst_bus[27];
wire inst_st_w       = inst_bus[32];
wire inst_stb        = inst_bus[1];
wire inst_sth        = inst_bus[0];
wire inst_b          = inst_bus[30];
wire inst_blt        = inst_bus[9];
wire inst_bge        = inst_bus[8];
wire inst_bltu       = inst_bus[7];
wire inst_bgeu       = inst_bus[6];
wire inst_jirl       = inst_bus[31];
wire inst_bl         = inst_bus[29];
wire inst_pcaddu12i  = inst_bus[17];
wire inst_slli_w     = inst_bus[37];
wire inst_srli_w     = inst_bus[36];
wire inst_srai_w     = inst_bus[35];
wire inst_addi_w     = inst_bus[34];
wire inst_ld_w       = inst_bus[33];
wire inst_lu12i_w    = inst_bus[26];
wire inst_slti       = inst_bus[25];
wire inst_sltui      = inst_bus[24];
wire inst_andi       = inst_bus[23];
wire inst_ori        = inst_bus[22];
wire inst_xori       = inst_bus[21];
wire inst_ldb        = inst_bus[5];
wire inst_ldh        = inst_bus[4];
wire inst_ldbu       = inst_bus[3];
wire inst_ldhu       = inst_bus[2];

// ==============control signal generation
assign src_reg_is_rd = inst_beq | inst_bne | inst_st_w | inst_stb | inst_sth | inst_blt | inst_bge | inst_bltu | inst_bgeu;

assign src1_is_pc    = inst_jirl | inst_bl | inst_pcaddu12i;

assign src2_is_imm   = inst_slli_w |
                       inst_srli_w |
                       inst_srai_w |
                       inst_addi_w |
                       inst_ld_w   |
                       inst_st_w   |
                       inst_lu12i_w|
                       inst_jirl   |
                       inst_bl     |
                       inst_pcaddu12i |
                       inst_slti    |
                       inst_sltui   |
                       inst_andi    |
                       inst_ori     |
                       inst_xori    |
                       inst_ldb     |
                       inst_ldh     |
                       inst_ldbu    |
                       inst_ldhu    |
                       inst_stb     |
                       inst_sth;

assign res_from_mem  = inst_ld_w | inst_ldb | inst_ldh | inst_ldbu | inst_ldhu;
assign dst_is_r1     = inst_bl;
assign gr_we         = ~inst_st_w & ~inst_beq & ~inst_bne & ~inst_b & ~inst_stb & ~inst_sth & ~inst_blt & ~inst_bge & ~inst_bltu & ~inst_bgeu;
assign mem_we        = inst_st_w | inst_stb | inst_sth;

endmodule
