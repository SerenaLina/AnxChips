`include "mycpu.h"

module op_decode(
    // 指令译码总线输入
    input  wire [`INST_BUS_WD-1:0] inst_bus,
    
    // 操作码输出
    output wire [27:0] alu_op,
    output wire [ 4:0] load_op,
    output wire [ 2:0] store_op
);

// ============== Unpack inst_bus
// Bit mapping (must match inst_decode.v)
wire inst_add_w      = inst_bus[45];
wire inst_sub_w      = inst_bus[44];
wire inst_slt        = inst_bus[43];
wire inst_sltu       = inst_bus[42];
wire inst_nor        = inst_bus[41];
wire inst_and        = inst_bus[40];
wire inst_or         = inst_bus[39];
wire inst_xor        = inst_bus[38];
wire inst_slli_w     = inst_bus[37];
wire inst_srli_w     = inst_bus[36];
wire inst_srai_w     = inst_bus[35];
wire inst_addi_w     = inst_bus[34];
wire inst_ld_w       = inst_bus[33];
wire inst_st_w       = inst_bus[32];
wire inst_jirl       = inst_bus[31];
wire inst_b          = inst_bus[30];
wire inst_bl         = inst_bus[29];
wire inst_beq        = inst_bus[28];
wire inst_bne        = inst_bus[27];
wire inst_lu12i_w    = inst_bus[26];
wire inst_slti       = inst_bus[25];
wire inst_sltui      = inst_bus[24];
wire inst_andi       = inst_bus[23];
wire inst_ori        = inst_bus[22];
wire inst_xori       = inst_bus[21];
wire inst_sllw       = inst_bus[20];
wire inst_srlw       = inst_bus[19];
wire inst_sraw       = inst_bus[18];
wire inst_pcaddu12i  = inst_bus[17];
wire inst_mulw       = inst_bus[16];
wire inst_mulhw      = inst_bus[15];
wire inst_mulhwu     = inst_bus[14];
wire inst_div        = inst_bus[13];
wire inst_modw       = inst_bus[12];
wire inst_divu       = inst_bus[11];
wire inst_modwu      = inst_bus[10];
wire inst_blt        = inst_bus[9];
wire inst_bge        = inst_bus[8];
wire inst_bltu       = inst_bus[7];
wire inst_bgeu       = inst_bus[6];
wire inst_ldb        = inst_bus[5];
wire inst_ldh        = inst_bus[4];
wire inst_ldbu       = inst_bus[3];
wire inst_ldhu       = inst_bus[2];
wire inst_stb        = inst_bus[1];
wire inst_sth        = inst_bus[0];

// ==============decode operation
assign load_op[0] = inst_ld_w;
assign load_op[1] = inst_ldb;
assign load_op[2] = inst_ldh;
assign load_op[3] = inst_ldbu;
assign load_op[4] = inst_ldhu;

assign store_op[0] = inst_st_w;
assign store_op[1] = inst_stb;
assign store_op[2] = inst_sth;

assign alu_op[ 0] = inst_add_w | inst_addi_w | inst_ld_w | inst_st_w
                    | inst_jirl | inst_bl | inst_ldb | inst_ldh | inst_ldbu | inst_ldhu | inst_stb | inst_sth;
assign alu_op[ 1] = inst_sub_w;
assign alu_op[ 2] = inst_slt;
assign alu_op[ 3] = inst_sltu;
assign alu_op[ 4] = inst_and;
assign alu_op[ 5] = inst_nor;
assign alu_op[ 6] = inst_or;
assign alu_op[ 7] = inst_xor;
assign alu_op[ 8] = inst_slli_w;
assign alu_op[ 9] = inst_srli_w;
assign alu_op[10] = inst_srai_w;
assign alu_op[11] = inst_lu12i_w;
assign alu_op[12] = inst_slti;
assign alu_op[13] = inst_sltui;
assign alu_op[14] = inst_andi;
assign alu_op[15] = inst_ori;
assign alu_op[16] = inst_xori;
assign alu_op[17] = inst_sllw;
assign alu_op[18] = inst_srlw;
assign alu_op[19] = inst_sraw;
assign alu_op[20] = inst_pcaddu12i;
assign alu_op[21] = inst_mulw;
assign alu_op[22] = inst_mulhw;
assign alu_op[23] = inst_mulhwu;
assign alu_op[24] = inst_div;
assign alu_op[25] = inst_modw;
assign alu_op[26] = inst_divu;
assign alu_op[27] = inst_modwu;

endmodule
