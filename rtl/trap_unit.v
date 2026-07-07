module trap_unit (
    input wire        clk,
    input wire        rst,
    
    // WB阶段输入的所有异常标�?
    input wire        wb_has_int,
    input wire [5:0]  wb_int_ecode,
    input wire [7:0]  wb_int_esubcode,
    input wire        wb_ex_adef,
    input wire        wb_ex_brk,
    input wire        wb_ex_ine,
    input wire        wb_ex_ipe,
    input wire        wb_ex_ale,
    input wire        wb_is_syscall,
    input wire        wb_is_ertn,
    input wire [1:0]  wb_inst_tlb_ex,
    input wire [2:0]  wb_data_tlb_ex,
    input wire        wb_need_cancel,
    
    // 输出
    output reg        trap_ex_valid,      // 有异常发�?
    output reg [5:0]  trap_ecode,         // �?终ecode
    output reg [7:0]  trap_esubcode,      // �?终esubcode
    output wire       trap_flush,         // 冲刷流水�?
    output wire       trap_ertn           // 是否是ertn指令
);

    // LoongArch 异常优先�? (从高到低)
    localparam INT  = 6'h00;
    localparam TLBR = 6'h3F;
    localparam PIL  = 6'h01;
    localparam PIS  = 6'h02;
    localparam PIF  = 6'h03;
    localparam PME  = 6'h04;
    localparam PPI  = 6'h07;
    localparam ADEF = 6'h08;
    localparam ALE  = 6'h09;
    localparam SYS  = 6'h0B;
    localparam BRK  = 6'h0C;
    localparam INE  = 6'h0D;
    localparam IPE  = 6'h0E;

    // 优先级仲�?
    always @(*) begin
        trap_ex_valid  = 1'b0;
        trap_ecode     = 6'h00;
        trap_esubcode  = 8'h00;

        // 注意：ertn指令也会置位trap_ex_valid，但ecode保持�?0
        // 这是为了兼容原Wb_stage的行�?
        // 当wb_need_cancel=1时，不触发异常（与原Wb_stage�?致）
        // ertn is NOT an exception — it is handled by wb_is_ertn separately
        if (!wb_need_cancel && !wb_is_ertn) begin
            if (wb_has_int) begin
                trap_ex_valid = 1'b1;
                trap_ecode    = wb_int_ecode;
                trap_esubcode = wb_int_esubcode;
            end
            else if (wb_inst_tlb_ex == 2'b01 || wb_data_tlb_ex == 3'b001) begin
                trap_ex_valid = 1'b1;
                trap_ecode    = TLBR;
            end
            else if (wb_data_tlb_ex == 3'b010) begin
                trap_ex_valid = 1'b1;
                trap_ecode    = PIL;
            end
            else if (wb_data_tlb_ex == 3'b011) begin
                trap_ex_valid = 1'b1;
                trap_ecode    = PIS;
            end
            else if (wb_inst_tlb_ex == 2'b10) begin
                trap_ex_valid = 1'b1;
                trap_ecode    = PIF;
            end
            else if (wb_data_tlb_ex == 3'b101) begin
                trap_ex_valid = 1'b1;
                trap_ecode    = PME;
            end
            else if (wb_inst_tlb_ex == 2'b11 || wb_data_tlb_ex == 3'b100) begin
                trap_ex_valid = 1'b1;
                trap_ecode    = PPI;
            end
            else if (wb_ex_adef) begin
                trap_ex_valid = 1'b1;
                trap_ecode    = ADEF;
            end
            else if (wb_ex_ale) begin
                trap_ex_valid = 1'b1;
                trap_ecode    = ALE;
            end
            else if (wb_is_syscall) begin
                trap_ex_valid = 1'b1;
                trap_ecode    = SYS;
            end
            else if (wb_ex_brk) begin
                trap_ex_valid = 1'b1;
                trap_ecode    = BRK;
            end
            else if (wb_ex_ipe) begin
                trap_ex_valid = 1'b1;
                trap_ecode    = IPE;
            end
            else if (wb_ex_ine) begin
                trap_ex_valid = 1'b1;
                trap_ecode    = INE;
            end
        end
    end
    

    assign trap_flush = trap_ex_valid || wb_is_ertn;
    assign trap_ertn  = wb_is_ertn;

endmodule
