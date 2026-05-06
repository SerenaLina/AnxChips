module interrupt (
    input wire clk,
    input wire rst,
    
    // CSR 输入
    input wire [12:0] csr_estat_is,
    input wire [12:0] csr_ecfg_lie,
    input wire        csr_crmd_ie,
    
    // 外部中断输入 (高电平有效)
    input wire [7:0] ext_intrpt,
    
    // 输出 - 在ID阶段产生，通过流水线传递
    output wire       int_has_int,
    output wire [5:0] int_ecode,
    output wire [7:0] int_esubcode
);

    // 中断检测逻辑
    // 1. 内部CSR中断: csr_estat_is & csr_ecfg_lie
    // 2. 外部中断: ext_intrpt (直接来自外部)
    wire [12:0] int_masked = csr_estat_is & csr_ecfg_lie;
    wire        has_internal_int = |int_masked;
    wire        has_external_int = |ext_intrpt;   // 任一外部中断有效
    
    // 当IE使能且(有内部中断或外部中断)时产生中断
    wire        has_int = csr_crmd_ie && (has_internal_int || has_external_int);
    
    assign int_has_int    = has_int;
    assign int_ecode      = 6'h00;    // INT
    assign int_esubcode   = 8'h00;

endmodule