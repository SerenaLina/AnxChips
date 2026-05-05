module interrupt (
    input wire clk,
    input wire rst,
    
    // CSR 输入
    input wire [12:0] csr_estat_is,
    input wire [12:0] csr_ecfg_lie,
    input wire        csr_crmd_ie,
    
    // 输出 - 在ID阶段产生，通过流水线传递
    output wire       int_has_int,
    output wire [5:0] int_ecode,
    output wire [7:0] int_esubcode
);

    // 中断检测逻辑
    wire [12:0] int_masked = csr_estat_is & csr_ecfg_lie;
    wire        has_int    = csr_crmd_ie && (|int_masked);
    
    assign int_has_int    = has_int;
    assign int_ecode      = 6'h00;    // INT
    assign int_esubcode   = 8'h00;

endmodule
