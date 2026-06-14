module ExE2_reg (
    input wire clk,
    input wire rst,
    input wire exe1_ready_go,
    input wire wb_ex,
    input wire wb_is_ertn,
    input wire exe2_allow_in,
    input wire mem_allow_in,
    input wire exe2_ready_go,
    input wire exe2_addr_shake_ok,
    input wire mem_data_shake_ok,
    input wire mem_need_and_data_ok,

    input wire[4:0] exe1_rd,
    input wire[31:0] exe1_src1,
    input wire[31:0] exe1_src2,
    input wire exe1_ref_we,
    input wire[4:0] exe1_alu_op,
    input wire exe1_dram_re,
    input wire exe1_dram_we,
    input wire [11:0] exe1_imm12,
    input wire exe1_src2_is_imm12,
    input wire exe1_src2_is_imm5,
    input wire [4:0] exe1_imm5,
    input wire [31:0] exe1_pc,
    input wire [15:0] exe1_imm16,
    input wire [25:0] exe1_imm26,
    input wire exe1_src2_is_imm26,
    input wire exe1_src2_is_imm16,
    input wire exe1_res_from_dram,
    input wire [31:0] exe1_dram_wdata,
    input wire[19:0] exe1_imm20,
    input wire exe1_src2_is_imm20,
    input wire [31:0] exe1_rf_src1,
    input wire [31:0] exe1_rf_src2,
    input wire exe1_zero_extend,
    input wire exe1_rdram_need_zero_extend,
    input wire exe1_rdram_need_signed_extend,
    input wire [1:0] exe1_rdram_num,
    input wire[1:0] exe1_wdram_num,
    input wire [13:0] exe1_csr_num,
    input wire exe1_csr_we,
    input wire exe1_is_ertn,
    input wire exe1_is_syscall,
    input wire exe1_res_from_csr,
    input wire [31:0] exe1_csr_wmask,
    input wire [31:0] exe1_csr_wdata,
    input wire exe1_ex_adef,
    input wire exe1_ex_brk,
    input wire exe1_ex_ine,
    input wire exe1_ex_ale_h,
    input wire exe1_ex_ale_w,
    input wire exe1_has_int,
    input wire [5:0] exe1_int_ecode,
    input wire [7:0] exe1_int_esubcode,
    input wire [4:0]exe1_rj,
    input wire [31:0]exe1_res_of_cnt,
    input wire exe1_res_is_rj,
    input wire exe1_res_from_cnt,
    input wire exe1_res_from_tid,
    input wire exe1_need_data_sram,
    input wire exe1_need_cancel,
    input wire exe1_inst_tlbrd,
    input wire exe1_inst_tlbsrch,
    input wire exe1_tlb_wr_en,
    input wire exe1_tlb_we,
    input wire exe1_tlb_fill_en,
    input wire [9:0] exe1_invtlb_asid,
    input wire [4:0] exe1_invtlb_op,
    input wire [18:0] exe1_invtlb_va,
    input wire exe1_invtlb_valid,
    input wire exe1_is_st,
    input wire exe1_is_ld,
    input wire exe1_tlb_or_csr_we,
    input wire [1:0]exe1_inst_tlb_ex,
    input wire [31:0] exe1_alu_result,
    input wire exe1_br_taken,
    input wire [31:0] exe1_br_target,
    input wire exe1_ex_ale,
    input wire [31:0] exe1_inst,

    output reg [4:0] exe2_rd,
    output reg [31:0] exe2_src1,
    output reg [31:0] exe2_src2,
    output reg exe2_ref_we,
    output reg [4:0] exe2_alu_op,
    output reg exe2_dram_re,
    output reg exe2_dram_we,
    output reg [11:0] exe2_imm12,
    output reg exe2_src2_is_imm12,
    output reg exe2_src2_is_imm5,
    output reg [4:0] exe2_imm5,
    output reg [31:0] exe2_pc,
    output reg [15:0] exe2_imm16,
    output reg [25:0] exe2_imm26,
    output reg exe2_src2_is_imm26,
    output reg exe2_src2_is_imm16,
    output reg exe2_res_from_dram,
    output reg [31:0] exe2_dram_wdata,
    output reg [19:0] exe2_imm20,
    output reg exe2_src2_is_imm20,
    output reg [31:0] exe2_rf_src1,
    output reg [31:0] exe2_rf_src2,
    output reg exe2_zero_extend,
    output reg exe2_rdram_need_zero_extend,
    output reg exe2_rdram_need_signed_extend,
    output reg [1:0]exe2_rdram_num,
    output reg [1:0]exe2_wdram_num,
    output reg [13:0] exe2_csr_num,
    output reg exe2_csr_we,
    output reg exe2_is_ertn,
    output reg exe2_is_syscall,
    output reg exe2_res_from_csr,
    output reg [31:0] exe2_csr_wmask,
    output reg [31:0] exe2_csr_wdata,
    output reg exe2_ex_adef,
    output reg exe2_ex_brk,
    output reg exe2_ex_ine,
    output reg exe2_ex_ale_h,
    output reg exe2_ex_ale_w,
    output reg exe2_has_int,
    output reg [5:0] exe2_int_ecode,
    output reg [7:0] exe2_int_esubcode,
    output reg [4:0]exe2_rj,
    output reg [31:0]exe2_res_of_cnt,
    output reg exe2_res_is_rj,
    output reg exe2_res_from_cnt,
    output reg exe2_res_from_tid,
    output reg exe2_need_data_sram,
    output reg exe2_need_cancel,
    output reg exe2_inst_tlbrd,
    output reg exe2_inst_tlbsrch,
    output reg exe2_tlb_wr_en,
    output reg exe2_tlb_we,
    output reg exe2_tlb_fill_en,
    output reg [9:0] exe2_invtlb_asid,
    output reg [4:0] exe2_invtlb_op,
    output reg [18:0] exe2_invtlb_va,
    output reg exe2_invtlb_valid,
    output reg exe2_is_st,
    output reg exe2_is_ld,
    output reg exe2_tlb_or_csr_we,
    output reg [1:0]exe2_inst_tlb_ex,
    output reg [31:0] exe2_alu_result,
    output reg exe2_br_taken,
    output reg [31:0] exe2_br_target,
    output reg exe2_ex_ale,
    output reg [31:0] exe2_inst
);

always @(posedge clk) begin
    if (rst || wb_ex===1'b1 || wb_is_ertn===1'b1) begin
        exe2_rd <= 5'd0;
        exe2_src1 <= 32'd0;
        exe2_src2 <= 32'd0;
        exe2_ref_we <= 1'b0;
        exe2_alu_op <= 4'd0;
        exe2_dram_re <= 1'b0;
        exe2_dram_we <= 1'b0;
        exe2_imm12 <= 12'd0;
        exe2_src2_is_imm12 <= 1'b0;
        exe2_src2_is_imm5 <= 1'b0;
        exe2_imm5 <= 5'd0;
        exe2_pc <= 32'd0;
        exe2_imm16 <= 16'd0;
        exe2_imm26 <= 26'd0;
        exe2_src2_is_imm26 <= 1'b0;
        exe2_src2_is_imm16 <= 1'b0;
        exe2_res_from_dram <= 1'b0;
        exe2_dram_wdata <= 32'd0;
        exe2_imm20 <= 20'd0;
        exe2_src2_is_imm20 <= 1'b0;
        exe2_rf_src1 <= 32'b0;
        exe2_rf_src2 <= 32'b0;
        exe2_zero_extend <= 1'b0;
        exe2_rdram_need_zero_extend <= 1'b0;
        exe2_rdram_need_signed_extend <= 1'b0;
        exe2_rdram_num <= 2'b0;
        exe2_wdram_num <= 2'b0;
        exe2_csr_num <= 14'b0;
        exe2_csr_we <= 1'b0;
        exe2_is_ertn <= 1'b0;
        exe2_is_syscall <= 1'b0;
        exe2_res_from_csr <= 1'b0;
        exe2_csr_wmask <= 32'b0;
        exe2_csr_wdata <= 32'b0;
        exe2_ex_adef <= 1'b0;
        exe2_ex_ale_h <= 1'b0;
        exe2_ex_ale_w <= 1'b0;
        exe2_ex_brk <= 1'b0;
        exe2_ex_ine <= 1'b0;
        exe2_has_int <= 1'b0;
        exe2_int_ecode <= 6'b0;
        exe2_int_esubcode <= 8'b0;
        exe2_rj <= 5'b0;
        exe2_res_of_cnt <= 32'b0;
        exe2_res_is_rj <= 1'b0;
        exe2_res_from_cnt <= 1'b0;
        exe2_res_from_tid <= 1'b0;
        exe2_need_data_sram <= 1'b0;
        exe2_need_cancel <= 1'b0;
        exe2_inst_tlbrd <= 1'b0;
        exe2_inst_tlbsrch <= 1'b0;
        exe2_tlb_wr_en <= 1'b0;
        exe2_tlb_we <= 1'b0;
        exe2_tlb_fill_en <= 1'b0;
        exe2_invtlb_asid <= 10'b0;
        exe2_invtlb_op <= 5'b0;
        exe2_invtlb_va <= 19'b0;
        exe2_invtlb_valid <= 1'b0;
        exe2_is_st <= 1'b0;
        exe2_is_ld <= 1'b0;
        exe2_tlb_or_csr_we <= 1'b0;
        exe2_inst_tlb_ex <= 2'b0;
        exe2_alu_result <= 32'b0;
        exe2_br_taken <= 1'b0;
        exe2_br_target <= 32'b0;
        exe2_ex_ale <= 1'b0;
        exe2_inst <= 32'd0;
    end else begin
        casez (!(exe1_ready_go===1'b0) && exe2_allow_in)
            1'b0: begin  // not ready
                if (!(exe2_ready_go===1'b0) && mem_allow_in==1'b1) begin
                    // EXE2 done, MEM can accept → clear (nop bubble forward)
                    exe2_rd <= 5'd0;
                    exe2_src1 <= 32'd0;
                    exe2_src2 <= 32'd0;
                    exe2_ref_we <= 1'b0;
                    exe2_alu_op <= 4'd0;
                    exe2_dram_re <= 1'b0;
                    exe2_dram_we <= 1'b0;
                    exe2_imm12 <= 12'd0;
                    exe2_src2_is_imm12 <= 1'b0;
                    exe2_src2_is_imm5 <= 1'b0;
                    exe2_imm5 <= 5'd0;
                    exe2_pc <= 32'd0;
                    exe2_imm16 <= 16'd0;
                    exe2_imm26 <= 26'd0;
                    exe2_src2_is_imm26 <= 1'b0;
                    exe2_src2_is_imm16 <= 1'b0;
                    exe2_res_from_dram <= 1'b0;
                    exe2_dram_wdata <= 32'd0;
                    exe2_imm20 <= 20'd0;
                    exe2_src2_is_imm20 <= 1'b0;
                    exe2_rf_src1 <= 32'b0;
                    exe2_rf_src2 <= 32'b0;
                    exe2_zero_extend <= 1'b0;
                    exe2_rdram_need_zero_extend <= 1'b0;
                    exe2_rdram_need_signed_extend <= 1'b0;
                    exe2_rdram_num <= 2'b0;
                    exe2_wdram_num <= 2'b0;
                    exe2_csr_num <= 14'b0;
                    exe2_csr_we <= 1'b0;
                    exe2_is_ertn <= 1'b0;
                    exe2_is_syscall <= 1'b0;
                    exe2_res_from_csr <= 1'b0;
                    exe2_csr_wmask <= 32'b0;
                    exe2_csr_wdata <= 32'b0;
                    exe2_ex_adef <= 1'b0;
                    exe2_ex_ale_h <= 1'b0;
                    exe2_ex_ale_w <= 1'b0;
                    exe2_ex_brk <= 1'b0;
                    exe2_ex_ine <= 1'b0;
                    exe2_has_int <= 1'b0;
                    exe2_int_ecode <= 6'b0;
                    exe2_int_esubcode <= 8'b0;
                    exe2_rj <= 5'b0;
                    exe2_res_of_cnt <= 32'b0;
                    exe2_res_is_rj <= 1'b0;
                    exe2_res_from_cnt <= 1'b0;
                    exe2_res_from_tid <= 1'b0;
                    exe2_need_data_sram <= 1'b0;
                    exe2_need_cancel <= 1'b0;
                    exe2_inst_tlbrd <= 1'b0;
                    exe2_inst_tlbsrch <= 1'b0;
                    exe2_tlb_wr_en <= 1'b0;
                    exe2_tlb_we <= 1'b0;
                    exe2_tlb_fill_en <= 1'b0;
                    exe2_invtlb_asid <= 10'b0;
                    exe2_invtlb_op <= 5'b0;
                    exe2_invtlb_va <= 19'b0;
                    exe2_invtlb_valid <= 1'b0;
                    exe2_is_st <= 1'b0;
                    exe2_is_ld <= 1'b0;
                    exe2_tlb_or_csr_we <= 1'b0;
                    exe2_inst_tlb_ex <= 2'b0;
                    exe2_alu_result <= 32'b0;
                    exe2_br_taken <= 1'b0;
                    exe2_br_target <= 32'b0;
                    exe2_ex_ale <= 1'b0;
                    exe2_inst <= 32'd0;
                end else if (exe2_addr_shake_ok===1'b0 || mem_data_shake_ok===1'b0 || mem_need_and_data_ok==1'b1) begin
                    // stall - keep current values
                    exe2_rd <= exe2_rd;
                    exe2_src1 <= exe2_src1;
                    exe2_src2 <= exe2_src2;
                    exe2_ref_we <= exe2_ref_we;
                    exe2_alu_op <= exe2_alu_op;
                    exe2_dram_re <= exe2_dram_re;
                    exe2_dram_we <= exe2_dram_we;
                    exe2_imm12 <= exe2_imm12;
                    exe2_src2_is_imm12 <= exe2_src2_is_imm12;
                    exe2_src2_is_imm5 <= exe2_src2_is_imm5;
                    exe2_imm5 <= exe2_imm5;
                    exe2_pc <= exe2_pc;
                    exe2_imm16 <= exe2_imm16;
                    exe2_imm26 <= exe2_imm26;
                    exe2_src2_is_imm26 <= exe2_src2_is_imm26;
                    exe2_src2_is_imm16 <= exe2_src2_is_imm16;
                    exe2_res_from_dram <= exe2_res_from_dram;
                    exe2_dram_wdata <= exe2_dram_wdata;
                    exe2_imm20 <= exe2_imm20;
                    exe2_src2_is_imm20 <= exe2_src2_is_imm20;
                    exe2_rf_src1 <= exe2_rf_src1;
                    exe2_rf_src2 <= exe2_rf_src2;
                    exe2_zero_extend <= exe2_zero_extend;
                    exe2_rdram_need_zero_extend <= exe2_rdram_need_zero_extend;
                    exe2_rdram_need_signed_extend <= exe2_rdram_need_signed_extend;
                    exe2_rdram_num <= exe2_rdram_num;
                    exe2_wdram_num <= exe2_wdram_num;
                    exe2_csr_num <= exe2_csr_num;
                    exe2_csr_we <= exe2_csr_we;
                    exe2_is_ertn <= exe2_is_ertn;
                    exe2_is_syscall <= exe2_is_syscall;
                    exe2_res_from_csr <= exe2_res_from_csr;
                    exe2_csr_wmask <= exe2_csr_wmask;
                    exe2_csr_wdata <= exe2_csr_wdata;
                    exe2_ex_adef <= exe2_ex_adef;
                    exe2_ex_ale_h <= exe2_ex_ale_h;
                    exe2_ex_ale_w <= exe2_ex_ale_w;
                    exe2_ex_brk <= exe2_ex_brk;
                    exe2_ex_ine <= exe2_ex_ine;
                    exe2_has_int <= exe2_has_int;
                    exe2_int_ecode <= exe2_int_ecode;
                    exe2_int_esubcode <= exe2_int_esubcode;
                    exe2_rj <= exe2_rj;
                    exe2_res_of_cnt <= exe2_res_of_cnt;
                    exe2_res_is_rj <= exe2_res_is_rj;
                    exe2_res_from_cnt <= exe2_res_from_cnt;
                    exe2_res_from_tid <= exe2_res_from_tid;
                    exe2_need_data_sram <= exe2_need_data_sram;
                    exe2_need_cancel <= exe2_need_cancel;
                    exe2_inst_tlbrd <= exe2_inst_tlbrd;
                    exe2_inst_tlbsrch <= exe2_inst_tlbsrch;
                    exe2_tlb_wr_en <= exe2_tlb_wr_en;
                    exe2_tlb_we <= exe2_tlb_we;
                    exe2_tlb_fill_en <= exe2_tlb_fill_en;
                    exe2_invtlb_asid <= exe2_invtlb_asid;
                    exe2_invtlb_op <= exe2_invtlb_op;
                    exe2_invtlb_va <= exe2_invtlb_va;
                    exe2_invtlb_valid <= exe2_invtlb_valid;
                    exe2_is_st <= exe2_is_st;
                    exe2_is_ld <= exe2_is_ld;
                    exe2_tlb_or_csr_we <= exe2_tlb_or_csr_we;
                    exe2_inst_tlb_ex <= exe2_inst_tlb_ex;
                    exe2_alu_result <= exe2_alu_result;
                    exe2_br_taken <= exe2_br_taken;
                    exe2_br_target <= exe2_br_target;
                    exe2_ex_ale <= exe2_ex_ale;
                    exe2_inst <= exe2_inst;
                end else begin
                    // clear
                    exe2_rd <= 5'd0;
                    exe2_src1 <= 32'd0;
                    exe2_src2 <= 32'd0;
                    exe2_ref_we <= 1'b0;
                    exe2_alu_op <= 4'd0;
                    exe2_dram_re <= 1'b0;
                    exe2_dram_we <= 1'b0;
                    exe2_imm12 <= 12'd0;
                    exe2_src2_is_imm12 <= 1'b0;
                    exe2_src2_is_imm5 <= 1'b0;
                    exe2_imm5 <= 5'd0;
                    exe2_pc <= 32'd0;
                    exe2_imm16 <= 16'd0;
                    exe2_imm26 <= 26'd0;
                    exe2_src2_is_imm26 <= 1'b0;
                    exe2_src2_is_imm16 <= 1'b0;
                    exe2_res_from_dram <= 1'b0;
                    exe2_dram_wdata <= 32'd0;
                    exe2_imm20 <= 20'd0;
                    exe2_src2_is_imm20 <= 1'b0;
                    exe2_rf_src1 <= 32'b0;
                    exe2_rf_src2 <= 32'b0;
                    exe2_zero_extend <= 1'b0;
                    exe2_rdram_need_zero_extend <= 1'b0;
                    exe2_rdram_need_signed_extend <= 1'b0;
                    exe2_rdram_num <= 2'b0;
                    exe2_wdram_num <= 2'b0;
                    exe2_csr_num <= 14'b0;
                    exe2_csr_we <= 1'b0;
                    exe2_is_ertn <= 1'b0;
                    exe2_is_syscall <= 1'b0;
                    exe2_res_from_csr <= 1'b0;
                    exe2_csr_wmask <= 32'b0;
                    exe2_csr_wdata <= 32'b0;
                    exe2_ex_adef <= 1'b0;
                    exe2_ex_ale_h <= 1'b0;
                    exe2_ex_ale_w <= 1'b0;
                    exe2_ex_brk <= 1'b0;
                    exe2_ex_ine <= 1'b0;
                    exe2_has_int <= 1'b0;
                    exe2_int_ecode <= 6'b0;
                    exe2_int_esubcode <= 8'b0;
                    exe2_rj <= 5'b0;
                    exe2_res_of_cnt <= 32'b0;
                    exe2_res_is_rj <= 1'b0;
                    exe2_res_from_cnt <= 1'b0;
                    exe2_res_from_tid <= 1'b0;
                    exe2_need_data_sram <= 1'b0;
                    exe2_need_cancel <= 1'b0;
                    exe2_inst_tlbrd <= 1'b0;
                    exe2_inst_tlbsrch <= 1'b0;
                    exe2_tlb_wr_en <= 1'b0;
                    exe2_tlb_we <= 1'b0;
                    exe2_tlb_fill_en <= 1'b0;
                    exe2_invtlb_asid <= 10'b0;
                    exe2_invtlb_op <= 5'b0;
                    exe2_invtlb_va <= 19'b0;
                    exe2_invtlb_valid <= 1'b0;
                    exe2_is_st <= 1'b0;
                    exe2_is_ld <= 1'b0;
                    exe2_tlb_or_csr_we <= 1'b0;
                    exe2_inst_tlb_ex <= 2'b0;
                    exe2_alu_result <= 32'b0;
                    exe2_br_taken <= 1'b0;
                    exe2_br_target <= 32'b0;
                    exe2_ex_ale <= 1'b0;
                    exe2_inst <= 32'd0;
                end
            end
            default: begin  // ready — latch from EXE1
                exe2_rd <= exe1_rd;
                exe2_src1 <= exe1_src1;
                exe2_src2 <= exe1_src2;
                exe2_ref_we <= exe1_ref_we;
                exe2_alu_op <= exe1_alu_op;
                exe2_dram_re <= exe1_dram_re;
                exe2_dram_we <= exe1_dram_we;
                exe2_imm12 <= exe1_imm12;
                exe2_src2_is_imm12 <= exe1_src2_is_imm12;
                exe2_src2_is_imm5 <= exe1_src2_is_imm5;
                exe2_imm5 <= exe1_imm5;
                exe2_pc <= exe1_pc;
                exe2_imm16 <= exe1_imm16;
                exe2_imm26 <= exe1_imm26;
                exe2_src2_is_imm26 <= exe1_src2_is_imm26;
                exe2_src2_is_imm16 <= exe1_src2_is_imm16;
                exe2_res_from_dram <= exe1_res_from_dram;
                exe2_dram_wdata <= exe1_dram_wdata;
                exe2_imm20 <= exe1_imm20;
                exe2_src2_is_imm20 <= exe1_src2_is_imm20;
                exe2_rf_src1 <= exe1_rf_src1;
                exe2_rf_src2 <= exe1_rf_src2;
                exe2_zero_extend <= exe1_zero_extend;
                exe2_rdram_need_zero_extend <= exe1_rdram_need_zero_extend;
                exe2_rdram_need_signed_extend <= exe1_rdram_need_signed_extend;
                exe2_rdram_num <= exe1_rdram_num;
                exe2_wdram_num <= exe1_wdram_num;
                exe2_csr_num <= exe1_csr_num;
                exe2_csr_we <= exe1_csr_we;
                exe2_is_ertn <= exe1_is_ertn;
                exe2_is_syscall <= exe1_is_syscall;
                exe2_res_from_csr <= exe1_res_from_csr;
                exe2_csr_wmask <= exe1_csr_wmask;
                exe2_csr_wdata <= exe1_csr_wdata;
                exe2_ex_adef <= exe1_ex_adef;
                exe2_ex_ale_h <= exe1_ex_ale_h;
                exe2_ex_ale_w <= exe1_ex_ale_w;
                exe2_ex_brk <= exe1_ex_brk;
                exe2_ex_ine <= exe1_ex_ine;
                exe2_has_int <= exe1_has_int;
                exe2_int_ecode <= exe1_int_ecode;
                exe2_int_esubcode <= exe1_int_esubcode;
                exe2_rj <= exe1_rj;
                exe2_res_of_cnt <= exe1_res_of_cnt;
                exe2_res_is_rj <= exe1_res_is_rj;
                exe2_res_from_cnt <= exe1_res_from_cnt;
                exe2_res_from_tid <= exe1_res_from_tid;
                exe2_need_data_sram <= exe1_need_data_sram;
                exe2_need_cancel <= exe1_need_cancel;
                exe2_inst_tlbrd <= exe1_inst_tlbrd;
                exe2_inst_tlbsrch <= exe1_inst_tlbsrch;
                exe2_tlb_wr_en <= exe1_tlb_wr_en;
                exe2_tlb_we <= exe1_tlb_we;
                exe2_tlb_fill_en <= exe1_tlb_fill_en;
                exe2_invtlb_asid <= exe1_invtlb_asid;
                exe2_invtlb_op <= exe1_invtlb_op;
                exe2_invtlb_va <= exe1_invtlb_va;
                exe2_invtlb_valid <= exe1_invtlb_valid;
                exe2_is_st <= exe1_is_st;
                exe2_is_ld <= exe1_is_ld;
                exe2_tlb_or_csr_we <= exe1_tlb_or_csr_we;
                exe2_inst_tlb_ex <= exe1_inst_tlb_ex;
                exe2_alu_result <= exe1_alu_result;
                exe2_br_taken <= exe1_br_taken;
                exe2_br_target <= exe1_br_target;
                exe2_ex_ale <= exe1_ex_ale;
                exe2_inst <= exe1_inst;
            end
        endcase
    end
end

endmodule
