`include "mycpu.h"

module exe_staller(
    input wire clk,
    input wire reset,
    
    // 执行阶段有效信号
    input wire es_valid,
    
    // ALU操作码（用于检测除法指令）
    input wire [27:0] alu_op,
    
    // 来自ALU的除法完成信号
    input wire ready_s,  // 有符号除法完成
    input wire ready_u,  // 无符号除法完成
    
    // 来自下一阶段的allowin信号
    input wire ms_allowin,
    
    // 流水线控制信号
    input wire ds_to_es_valid,
    
    // 输出信号
    output reg div_complete,
    output wire es_ready_go,
    output wire es_allowin,
    output wire es_to_ms_valid,
    output wire debug_es_div_complete
);

// 除法操作码索引
// alu_op[24] = inst_div
// alu_op[25] = inst_modw
// alu_op[26] = inst_divu
// alu_op[27] = inst_modwu

wire is_div_op = alu_op[24] || alu_op[25] || alu_op[26] || alu_op[27];

// 除法完成状态寄存器
always @(posedge clk) begin
    if (reset) begin
        div_complete <= 1'b0;
    end 
    else if (es_allowin && is_div_op) begin
        // 新的除法指令进入执行阶段，重置完成标志
        div_complete <= 1'b0; 
    end
    else if ((alu_op[24] || alu_op[25]) && ready_s) begin
        // 有符号除法完成
        div_complete <= 1'b1;
    end
    else if ((alu_op[26] || alu_op[27]) && ready_u) begin
        // 无符号除法完成
        div_complete <= 1'b1;
    end
end

// 执行阶段ready_go信号：如果是除法指令，等待除法完成；否则直接为1
assign es_ready_go = (es_valid && is_div_op) ? div_complete : 1'b1;

// 执行阶段allowin信号
assign es_allowin = !es_valid || (es_ready_go && ms_allowin);

// 执行阶段到内存阶段的有效信号
assign es_to_ms_valid = es_valid && es_ready_go;

// 调试信号
assign debug_es_div_complete = div_complete;

endmodule
