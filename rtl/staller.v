`include "mycpu.h"

module staller(
    // 指令译码总线输入
    input wire [`INST_BUS_WD-1:0] inst_bus,
    
    // 寄存器地址
    input wire [4:0] rj,
    input wire [4:0] rk,
    input wire [4:0] rd,
    
    // 前递目标寄存器
    input wire [4:0] es_to_ds_dest,
    input wire [4:0] ms_to_ds_dest,
    input wire [4:0] ws_to_ds_dest,
    
    // 执行阶段信号
    input wire es_res_from_mem,
    
    // 输出stall信号
    output wire rj_wait,
    output wire rk_wait,
    output wire rd_wait,
    output wire no_wait,
    output wire load_wait
);

// ============== Unpack inst_bus
// Bit mapping (must match inst_decode.v)
wire inst_b          = inst_bus[30];
wire inst_bl         = inst_bus[29];
wire inst_lu12i_w    = inst_bus[26];
wire inst_slli_w     = inst_bus[37];
wire inst_srli_w     = inst_bus[36];
wire inst_srai_w     = inst_bus[35];
wire inst_addi_w     = inst_bus[34];
wire inst_ld_w       = inst_bus[33];
wire inst_ldb        = inst_bus[5];
wire inst_ldh        = inst_bus[4];
wire inst_ldbu       = inst_bus[3];
wire inst_ldhu       = inst_bus[2];
wire inst_st_w       = inst_bus[32];
wire inst_stb        = inst_bus[1];
wire inst_sth        = inst_bus[0];
wire inst_jirl       = inst_bus[31];
wire inst_beq        = inst_bus[28];
wire inst_bne        = inst_bus[27];
wire inst_blt        = inst_bus[9];
wire inst_bge        = inst_bus[8];
wire inst_bltu       = inst_bus[7];
wire inst_bgeu       = inst_bus[6];

// ============== data stall 信号生成 ==============
wire src_no_rj;
wire src_no_rk;
wire src_no_rd;

assign src_no_rj = (inst_b | inst_bl | inst_lu12i_w) ? 1'b1 : 1'b0;

assign src_no_rk = inst_slli_w | inst_srli_w | inst_srai_w | inst_addi_w | 
                   inst_ld_w | inst_ldb | inst_ldh | inst_ldbu | inst_ldhu |
                   inst_st_w | inst_stb | inst_sth |
                   inst_jirl | 
                   inst_b | inst_bl | inst_beq | inst_bne | inst_lu12i_w | inst_blt | inst_bge | inst_bltu | inst_bgeu;

assign src_no_rd = ~inst_st_w & ~inst_stb & ~inst_sth & ~inst_beq & ~inst_bne & ~inst_blt & ~inst_bge & ~inst_bltu & ~inst_bgeu;

// ============== 数据冒险检测 ==============
assign rj_wait = ~src_no_rj && (rj != 5'b00000) 
                 && ((rj == es_to_ds_dest)  
                   || (rj == ms_to_ds_dest)    
                   || (rj == ws_to_ds_dest));   

assign rk_wait = ~src_no_rk && (rk != 5'b00000) 
                 && ((rk == es_to_ds_dest) 
                   || (rk == ms_to_ds_dest) 
                   || (rk == ws_to_ds_dest));

assign rd_wait = ~src_no_rd && (rd != 5'b00000) 
                 && ((rd == es_to_ds_dest) 
                   || (rd == ms_to_ds_dest) 
                   || (rd == ws_to_ds_dest));

assign no_wait = ~rj_wait && ~rk_wait && ~rd_wait;

// ============== Load-use 冒险检测 ==============
assign load_wait = ((rj == es_to_ds_dest) && es_res_from_mem) ||
                   ((rk == es_to_ds_dest) && es_res_from_mem) ||
                   ((rd == es_to_ds_dest) && es_res_from_mem);

endmodule
