`include "mycpu.h"

module forward(
    // 寄存器地址
    input wire [4:0] rj,
    input wire [4:0] rk,
    input wire [4:0] rd,
    
    // 前递目标寄存器
    input wire [4:0] es_to_ds_dest,
    input wire [4:0] ms_to_ds_dest,
    input wire [4:0] ws_to_ds_dest,
    
    // 前递数据
    input wire [31:0] es_result,
    input wire [31:0] ms_result,
    input wire [31:0] ws_result,
    
    // 寄存器文件数据
    input wire [31:0] rf_rdata1,
    input wire [31:0] rf_rdata2,
    
    // stall信号（用于选择前递或寄存器数据）
    input wire rj_wait,
    input wire rk_wait,
    input wire rd_wait,
    
    // 输出前递后的数据
    output wire [31:0] rj_value,
    output wire [31:0] rkd_value
);

// ============== rj 数据前递 ==============
// 当rj_wait为1时，选择前递数据；否则使用寄存器文件数据
assign rj_value = rj_wait ? ((rj == es_to_ds_dest) ? es_result :
                             (rj == ms_to_ds_dest) ? ms_result : ws_result)
                          : rf_rdata1;

// ============== rk/rd 数据前递 ==============
// 优先级：rk_wait > rd_wait > 寄存器文件
assign rkd_value = rk_wait ? ((rk == es_to_ds_dest) ? es_result :
                              (rk == ms_to_ds_dest) ? ms_result : ws_result) :
                   rd_wait ? ((rd == es_to_ds_dest) ? es_result :
                              (rd == ms_to_ds_dest) ? ms_result : ws_result) :
                   rf_rdata2;

endmodule
