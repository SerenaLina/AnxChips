`include "mycpu.h"

module branch(
    // 指令译码总线输入
    input  wire [`INST_BUS_WD-1:0] inst_bus,
    
    // 立即数生成信号
    input  wire need_si26,
    input  wire need_si16,
    
    // 指令字段
    input  wire [15:0] i16,
    input  wire [25:0] i26,
    
    // 数据比较
    input  wire [31:0] rj_value,
    input  wire [31:0] rkd_value,
    input  wire        rj_eq_rd,
    
    // PC相关
    input  wire [31:0] ds_pc,
    
    // 流水线控制
    input  wire        ds_valid,
    input  wire        load_wait,
    
    // 分支输出
    output wire        br_taken,
    output wire        br_cancel,
    output wire [31:0] br_target,
    output wire [31:0] br_offs,
    output wire [31:0] jirl_offs
);

// ============== Unpack inst_bus
// Bit mapping (must match inst_decode.v)
wire inst_beq        = inst_bus[28];
wire inst_bne        = inst_bus[27];
wire inst_jirl       = inst_bus[31];
wire inst_bl         = inst_bus[29];
wire inst_b          = inst_bus[30];
wire inst_blt        = inst_bus[9];
wire inst_bge        = inst_bus[8];
wire inst_bltu       = inst_bus[7];
wire inst_bgeu       = inst_bus[6];

// ==============branch offset generation
assign br_offs = need_si26 ? {{ 4{i26[25]}}, i26[25:0], 2'b0} :
                              {{14{i16[15]}}, i16[15:0], 2'b0} ;

assign jirl_offs = {{14{i16[15]}}, i16[15:0], 2'b0};

// ==============branch decision
assign br_taken = (   inst_beq  &&  rj_eq_rd
                   || inst_bne  && !rj_eq_rd
                   || inst_jirl
                   || inst_bl
                   || inst_b
                   || inst_blt  && ($signed(rj_value) < $signed(rkd_value))
                   || inst_bge  && ($signed(rj_value) >= $signed(rkd_value))
                   || inst_bltu && (rj_value < rkd_value)
                   || inst_bgeu && (rj_value >= rkd_value)
)  && ds_valid && ~load_wait;

assign br_cancel = br_taken;

assign br_target = (inst_beq || inst_bne || inst_bl || inst_b || inst_blt || inst_bge || inst_bltu || inst_bgeu) ? (ds_pc + br_offs) :
                                                   /*inst_jirl*/ (rj_value + jirl_offs);

endmodule
