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

    // 中断检测逻辑（统一走 ESTAT.IS & ECFG.LIE 的屏蔽路径）
    // 硬件外部中断已由 core_top 接入 CSR.ESTAT.IS[9:2]，故不再单独 OR 原始 ext_intrpt：
    //   原实现 has_external_int=|ext_intrpt 绕过了 ECFG.LIE 屏蔽（即使该硬件中断在
    //   ECFG 中被关闭也会触发），违反手册；且与 ESTAT 路径重复计数。改为统一屏蔽路径。
    wire [12:0] int_masked = csr_estat_is & csr_ecfg_lie;
    wire        has_masked_int = |int_masked;

    // 当 IE 使能且有 ECFG 使能的挂起中断时产生中断
    wire        has_int = csr_crmd_ie && has_masked_int;

    assign int_has_int    = has_int;
    assign int_ecode      = 6'h00;    // INT
    assign int_esubcode   = 8'h00;

endmodule