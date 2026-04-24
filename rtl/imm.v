`include "mycpu.h"

module imm(
    // 指令译码总线输入
    input  wire [`INST_BUS_WD-1:0] inst_bus,
    
    // 指令字段
    input  wire [ 4:0] rk,
    input  wire [11:0] i12,
    input  wire [19:0] i20,
    input  wire [15:0] i16,
    input  wire [25:0] i26,
    
    // 立即数输出
    output wire [31:0] imm,
    output wire need_ui5,
    output wire need_si12,
    output wire need_si16,
    output wire need_si20,
    output wire need_si26,
    output wire need_ui12,
    output wire src2_is_4
);

// ============== Unpack inst_bus
// Bit mapping (must match inst_decode.v)
wire inst_slli_w     = inst_bus[37];
wire inst_srli_w     = inst_bus[36];
wire inst_srai_w     = inst_bus[35];
wire inst_addi_w     = inst_bus[34];
wire inst_ld_w       = inst_bus[33];
wire inst_st_w       = inst_bus[32];
wire inst_slti       = inst_bus[25];
wire inst_sltui      = inst_bus[24];
wire inst_andi       = inst_bus[23];
wire inst_ori        = inst_bus[22];
wire inst_xori       = inst_bus[21];
wire inst_ldb        = inst_bus[5];
wire inst_ldh        = inst_bus[4];
wire inst_ldbu       = inst_bus[3];
wire inst_ldhu       = inst_bus[2];
wire inst_stb        = inst_bus[1];
wire inst_sth        = inst_bus[0];
wire inst_jirl       = inst_bus[31];
wire inst_beq        = inst_bus[28];
wire inst_bne        = inst_bus[27];
wire inst_blt        = inst_bus[9];
wire inst_bge        = inst_bus[8];
wire inst_bltu       = inst_bus[7];
wire inst_bgeu       = inst_bus[6];
wire inst_lu12i_w    = inst_bus[26];
wire inst_pcaddu12i  = inst_bus[17];
wire inst_b          = inst_bus[30];
wire inst_bl         = inst_bus[29];

// ==============imm generation
assign need_ui5   =  inst_slli_w | inst_srli_w | inst_srai_w;
assign need_si12  =  inst_addi_w | inst_ld_w | inst_st_w | inst_slti | inst_sltui | inst_ldb | inst_ldh | inst_ldbu | inst_ldhu | inst_stb | inst_sth;
assign need_si16  =  inst_jirl | inst_beq | inst_bne | inst_blt | inst_bge | inst_bltu | inst_bgeu;
assign need_si20  =  inst_lu12i_w | inst_pcaddu12i;
assign need_si26  =  inst_b | inst_bl;
assign need_ui12  =  inst_andi | inst_ori | inst_xori;
assign src2_is_4  =  inst_jirl | inst_bl;

assign imm = src2_is_4 ? 32'h4                      :
             need_si20 ? {i20[19:0], 12'b0}         :
             need_ui5  ? {27'b0, rk[4:0]}           :
             need_si12 ? {{20{i12[11]}}, i12[11:0]} :
            /*need_ui12*/{{20{1'b0}}, i12[11:0]} ;

endmodule
