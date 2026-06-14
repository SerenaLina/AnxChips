module ExE1_reg (
    input wire clk,
    input wire rst,
    input wire id_ready_go,
    input wire wb_ex,
    input wire wb_is_ertn,
    input wire mem_is_ertn,
    input wire exe1_div_is_doing,
    input wire exe1_allow_in,
    input wire exe2_allow_in,
    input wire exe1_ready_go,
    input wire[4:0] id_rd,
    input wire[31:0] id_src1,
    input wire[31:0] id_src2,
    input wire id_ref_we,
    input wire[4:0] id_alu_op,
    input wire id_dram_re,
    input wire id_dram_we,
    input wire [11:0] id_imm12,
    input wire id_src2_is_imm12,
    input wire id_src2_is_imm5,
    input wire [4:0] id_imm5,
    input wire [31:0] id_pc,
    input wire [15:0] id_imm16,
    input wire [25:0] id_imm26,
    input wire id_src2_is_imm26,
    input wire id_src2_is_imm16,
    input wire id_res_from_dram,
    input wire [31:0] id_dram_wdata,
    input wire[19:0] id_imm20,
    input wire id_src2_is_imm20,
    input wire id_zero_extend,
    input wire id_rdram_need_zero_extend,
    input wire id_rdram_need_signed_extend,
    input wire [1:0] id_rdram_num,
    input wire[1:0] id_wdram_num,
    input wire [13:0] id_csr_num,
    input wire id_csr_we,
    input wire id_is_ertn,
    input wire id_is_syscall,
    input wire id_res_from_csr,
    input wire [31:0] id_csr_wmask,
    input wire [31:0] id_csr_wdata,
    input wire id_ex_adef,
    input wire id_ex_brk,
    input wire id_ex_ine,
    input wire id_ex_ale_h,
    input wire id_ex_ale_w,
    input wire id_has_int,
    input wire [5:0] id_int_ecode,
    input wire [7:0] id_int_esubcode,
    input wire [4:0]id_rj,
    input wire [31:0]id_res_of_cnt,
    input wire id_res_is_rj,
    input wire id_res_from_cnt,
    input wire id_res_from_tid,
    input wire id_need_data_sram, 
    input wire id_need_cancel,
    input wire id_inst_tlbrd,
    input wire id_inst_tlbsrch,
    input wire id_tlb_wr_en,
    input wire id_tlb_we,
    input wire id_tlb_fill_en,
    input wire [9:0] id_invtlb_asid,
    input wire [4:0] id_invtlb_op,
    input wire [18:0] id_invtlb_va,
    input wire id_invtlb_valid,
    input wire id_is_st,
    input wire id_is_ld,
    input wire id_tlb_or_csr_we,
    input wire [1:0]id_inst_tlb_ex,
    input wire [31:0] id_inst,

    //input wire [31:0]id_csr_rdata,

    output reg [4:0] exe1_rd,
    output reg [31:0] exe1_src1,
    output reg [31:0] exe1_src2,
    output reg exe1_ref_we,
    output reg [4:0] exe1_alu_op,
    output reg exe1_dram_re,
    output reg exe1_dram_we,
    output reg [11:0] exe1_imm12,
    output reg exe1_src2_is_imm12,
    output reg exe1_src2_is_imm5,
    output reg [4:0] exe1_imm5,
    output reg [31:0] exe1_pc,
    output reg [15:0] exe1_imm16,
    output reg [25:0] exe1_imm26,
    output reg exe1_src2_is_imm26,
    output reg exe1_src2_is_imm16,
    output reg exe1_res_from_dram,
    output reg [31:0] exe1_dram_wdata,
    output reg [19:0] exe1_imm20,
    output reg exe1_src2_is_imm20,
    output reg [31:0] exe1_rf_src1,
    output reg [31:0] exe1_rf_src2,
    output reg exe1_zero_extend,
    output reg exe1_rdram_need_zero_extend,
    output reg exe1_rdram_need_signed_extend,
    output reg [1:0]exe1_rdram_num,
    output reg [1:0]exe1_wdram_num,
    output reg [13:0] exe1_csr_num,
    output reg exe1_csr_we,
    output reg exe1_is_ertn,
    output reg exe1_is_syscall,
    output reg exe1_res_from_csr,
    output reg [31:0] exe1_csr_wmask,
    output reg [31:0] exe1_csr_wdata,
    output reg exe1_ex_adef,
    output reg exe1_ex_brk,
    output reg exe1_ex_ine,
    output reg exe1_ex_ale_h,
    output reg exe1_ex_ale_w,
    output reg exe1_has_int,
    output reg [5:0] exe1_int_ecode,
    output reg [7:0] exe1_int_esubcode,
    output reg [4:0]exe1_rj,
    output reg [31:0]exe1_res_of_cnt,
    output reg exe1_res_is_rj,
    output reg exe1_res_from_cnt,
    output reg exe1_res_from_tid,
    output reg exe1_need_data_sram,
    output reg exe1_need_cancel,
    output reg exe1_inst_tlbrd,
    output reg exe1_inst_tlbsrch,
    output reg exe1_tlb_wr_en,
    output reg exe1_tlb_we,
    output reg exe1_tlb_fill_en,
    output reg [9:0] exe1_invtlb_asid,
    output reg [4:0] exe1_invtlb_op,
    output reg [18:0] exe1_invtlb_va,
    output reg exe1_invtlb_valid,
    output reg exe1_is_st,
    output reg exe1_is_ld,
    output reg exe1_tlb_or_csr_we,
    output reg [1:0]exe1_inst_tlb_ex,
    output reg [31:0] exe1_inst,
    output reg        exe1_dropped     // asserted when E1 has valid data stalled behind E2
);

always @(posedge clk) begin
    if (rst ||wb_ex===1'b1||wb_is_ertn===1'b1||mem_is_ertn===1'b1) begin
        exe1_rd <= 5'd0;
        exe1_src1 <= 32'd0;
        exe1_src2 <= 32'd0;
        exe1_ref_we <= 1'b0;
        exe1_alu_op <= 4'd0;
        exe1_dram_re <= 1'b0;
        exe1_dram_we <= 1'b0;
        exe1_imm12 <= 12'd0;
        exe1_src2_is_imm12 <= 1'b0;
        exe1_src2_is_imm5 <= 1'b0;
        exe1_imm5 <= 5'd0;
        exe1_pc <= 32'd0;
        exe1_imm16 <= 16'd0;
        exe1_imm26 <= 26'd0;
        exe1_src2_is_imm26 <= 1'b0;
        exe1_src2_is_imm16 <= 1'b0;
        exe1_res_from_dram <= 1'b0;
        exe1_dram_wdata <= 32'd0;
        exe1_imm20 <= 20'd0;
        exe1_src2_is_imm20 <= 1'b0;
        exe1_rf_src1 <= 32'b0;
        exe1_rf_src2 <= 32'b0;
        exe1_zero_extend<=1'b0;
        exe1_rdram_need_zero_extend<=1'b0;
        exe1_rdram_need_signed_extend<=1'b0;
        exe1_rdram_num<=2'b0;
        exe1_wdram_num<=2'b0;
        exe1_csr_num<=14'b0;
        exe1_csr_we<=1'b0;
        exe1_is_ertn<=1'b0;
        exe1_is_syscall<=1'b0;
        exe1_res_from_csr<=1'b0;
        exe1_csr_wmask<=32'b0;
        exe1_csr_wdata<=32'b0;
        exe1_ex_adef<=1'b0;
        exe1_ex_ale_h<=1'b0;
        exe1_ex_ale_w<=1'b0;
        exe1_ex_brk<=1'b0;
        exe1_ex_ine<=1'b0;
        exe1_has_int<=1'b0;
        exe1_int_ecode<=6'b0;
        exe1_int_esubcode<=8'b0;
        exe1_rj<=5'b0;
        exe1_res_of_cnt<=32'b0;
        exe1_res_is_rj<=1'b0;
        exe1_res_from_cnt<=1'b0;
        exe1_res_from_tid<=1'b0;
        exe1_need_data_sram<=1'b0;
        exe1_need_cancel <= 1'b0;
        exe1_inst_tlbrd <= 1'b0;
        exe1_inst_tlbsrch <= 1'b0;
        exe1_tlb_wr_en <= 1'b0;
        exe1_tlb_we <= 1'b0;
        exe1_tlb_fill_en <= 1'b0;
        exe1_invtlb_asid <= 10'b0;
        exe1_invtlb_op <= 5'b0;
        exe1_invtlb_va <= 19'b0;
        exe1_invtlb_valid <= 1'b0;
        exe1_is_st <= 1'b0;
        exe1_is_ld <= 1'b0;
        exe1_tlb_or_csr_we <= 1'b0;
        exe1_inst_tlb_ex <= 2'b0;
        exe1_inst <= 32'd0;
        exe1_dropped <= 1'b0;
        //exe_csr_rdata<=32'b0;
    end else begin
        casez (!(id_ready_go===1'b0)&&exe1_allow_in)

            1'b0: begin  // not ready, hold or clear
                if(!(exe1_ready_go===1'b0)&&exe2_allow_in==1'b1)
                begin
                exe1_rd <= 5'd0;
                exe1_src1 <= 32'd0;
                exe1_src2 <= 32'd0;
                exe1_ref_we <= 1'b0;
                exe1_alu_op <= 4'd0;
                exe1_dram_re <= 1'b0;
                exe1_dram_we <= 1'b0;
                exe1_imm12 <= 12'd0;
                exe1_src2_is_imm12 <= 1'b0;
                exe1_src2_is_imm5 <= 1'b0;
                exe1_imm5 <= 5'd0;
                 exe1_pc <= 32'd0;
                exe1_imm16 <= 16'd0;
                exe1_imm26 <= 26'd0;
                exe1_src2_is_imm26 <= 1'b0;
                exe1_src2_is_imm16 <= 1'b0;
                exe1_res_from_dram <= 1'b0;
                exe1_dram_wdata <= 32'd0;
                exe1_imm20 <= 20'd0;
                exe1_src2_is_imm20 <= 1'b0;
                exe1_rf_src1 <= 32'b0;
                exe1_rf_src2 <= 32'b0;
                exe1_zero_extend<=1'b0;
                exe1_rdram_need_zero_extend<=1'b0;
                exe1_rdram_need_signed_extend<=1'b0;
                exe1_rdram_num<=2'b0;
                exe1_wdram_num<=2'b0;
                exe1_csr_num<=14'b0;
                exe1_csr_we<=1'b0;
                exe1_is_ertn<=1'b0;
                exe1_is_syscall<=1'b0;
                exe1_res_from_csr<=1'b0;
                exe1_csr_wmask<=32'b0;
                exe1_csr_wdata<=32'b0;
                exe1_ex_adef<=1'b0;
                exe1_ex_ale_h<=1'b0;
                exe1_ex_ale_w<=1'b0;
                exe1_ex_brk<=1'b0;
                exe1_ex_ine<=1'b0;
                exe1_has_int<=1'b0;
                exe1_int_ecode<=6'b0;
                exe1_int_esubcode<=8'b0;
                exe1_rj<=5'b0;
                exe1_res_of_cnt<=32'b0;
                exe1_res_is_rj<=1'b0;
                exe1_res_from_cnt<=1'b0;
                exe1_res_from_tid<=1'b0;
                exe1_need_data_sram<=1'b0;
                exe1_need_cancel <= 1'b0;
                exe1_inst_tlbrd <= 1'b0;
                exe1_inst_tlbsrch <= 1'b0;
                exe1_tlb_wr_en <= 1'b0;
                exe1_tlb_we <= 1'b0;
                exe1_tlb_fill_en <= 1'b0;
                exe1_invtlb_asid <= 10'b0;
                exe1_invtlb_op <= 5'b0;
                exe1_invtlb_va <= 19'b0;
                exe1_invtlb_valid <= 1'b0;
                exe1_is_st <= 1'b0;
                exe1_is_ld <= 1'b0;
                exe1_tlb_or_csr_we <= 1'b0;
                exe1_inst_tlb_ex <= 2'b0;
                exe1_inst <= 32'd0;
                exe1_dropped <= 1'b0;
                end
                else if(exe1_div_is_doing)
                begin
                exe1_rd <= exe1_rd;
                exe1_src1 <= exe1_src1;
                exe1_src2 <= exe1_src2;
                exe1_ref_we <= exe1_ref_we;
                exe1_alu_op <= exe1_alu_op;
                exe1_dram_re <= exe1_dram_re;
                exe1_dram_we <= exe1_dram_we;
                exe1_imm12 <= exe1_imm12;
                exe1_src2_is_imm12 <= exe1_src2_is_imm12;
                exe1_src2_is_imm5 <= exe1_src2_is_imm5;
                exe1_imm5 <= exe1_imm5;
                exe1_pc <= exe1_pc;
                exe1_imm16 <= exe1_imm16;
                exe1_imm26 <= exe1_imm26;
                exe1_src2_is_imm26 <= exe1_src2_is_imm26;
                exe1_src2_is_imm16 <= exe1_src2_is_imm16;
                exe1_res_from_dram <= exe1_res_from_dram;
                exe1_dram_wdata <= exe1_dram_wdata;
                exe1_imm20 <= exe1_imm20;
                exe1_src2_is_imm20 <= exe1_src2_is_imm20;
                exe1_rf_src1 <= exe1_src1;
                exe1_rf_src2 <= exe1_src2;
                exe1_zero_extend<=exe1_zero_extend;
                exe1_rdram_need_zero_extend<=exe1_rdram_need_zero_extend;
                exe1_rdram_need_signed_extend<=exe1_rdram_need_signed_extend;
                exe1_rdram_num<=exe1_rdram_num;
                exe1_wdram_num<=exe1_wdram_num;
                exe1_csr_num<=exe1_csr_num;
                exe1_csr_we<=exe1_csr_we;
                exe1_is_ertn<=exe1_is_ertn;
                exe1_is_syscall<=exe1_is_syscall;
                exe1_res_from_csr<=exe1_res_from_csr;
                exe1_csr_wmask<=exe1_csr_wmask;
                exe1_csr_wdata<=exe1_csr_wdata;
                exe1_ex_adef<=exe1_ex_adef;
                exe1_ex_ale_h<=exe1_ex_ale_h;
                exe1_ex_ale_w<=exe1_ex_ale_w;
                exe1_ex_brk<=exe1_ex_brk;
                exe1_ex_ine<=exe1_ex_ine;
                exe1_has_int<=exe1_has_int;
                exe1_int_ecode<=exe1_int_ecode;
                exe1_int_esubcode<=exe1_int_esubcode;
                exe1_rj<=exe1_rj;
                exe1_res_of_cnt<=exe1_res_of_cnt;
                exe1_res_is_rj<=exe1_res_is_rj;
                exe1_res_from_cnt<=exe1_res_from_cnt;
                exe1_res_from_tid<=exe1_res_from_tid;
                exe1_need_data_sram<=exe1_need_data_sram; 
                exe1_need_cancel <= exe1_need_cancel;
                exe1_inst_tlbrd <= exe1_inst_tlbrd;
                exe1_inst_tlbsrch <= exe1_inst_tlbsrch;
                exe1_tlb_wr_en <= exe1_tlb_wr_en;
                exe1_tlb_we <= exe1_tlb_we;
                exe1_tlb_fill_en <= exe1_tlb_fill_en;
                exe1_invtlb_asid <= exe1_invtlb_asid;
                exe1_invtlb_op <= exe1_invtlb_op;
                exe1_invtlb_va <= exe1_invtlb_va;
                exe1_invtlb_valid <= exe1_invtlb_valid;
                exe1_is_st <= exe1_is_st;
                exe1_is_ld <= exe1_is_ld;
                exe1_tlb_or_csr_we <= exe1_tlb_or_csr_we;
                exe1_inst_tlb_ex <= exe1_inst_tlb_ex;
                exe1_inst <= exe1_inst;
                exe1_dropped <= 1'b0;
                end
                else
                begin
                // signal drop ONLY for real instructions (not bubbles, which have pc=0)
                exe1_dropped <= !(exe1_ready_go===1'b0) && (exe1_pc != 32'b0);
                exe1_rd <= 5'd0;
                exe1_src1 <= 32'd0;
                exe1_src2 <= 32'd0;
                exe1_ref_we <= 1'b0;
                exe1_alu_op <= 4'd0;
                exe1_dram_re <= 1'b0;
                exe1_dram_we <= 1'b0;
                exe1_imm12 <= 12'd0;
                exe1_src2_is_imm12 <= 1'b0;
                exe1_src2_is_imm5 <= 1'b0;
                exe1_imm5 <= 5'd0;
                 exe1_pc <= 32'd0;
                exe1_imm16 <= 16'd0;
                exe1_imm26 <= 26'd0;
                exe1_src2_is_imm26 <= 1'b0;
                exe1_src2_is_imm16 <= 1'b0;
                exe1_res_from_dram <= 1'b0;
                exe1_dram_wdata <= 32'd0;
                exe1_imm20 <= 20'd0;
                exe1_src2_is_imm20 <= 1'b0;
                exe1_rf_src1 <= 32'b0;
                exe1_rf_src2 <= 32'b0;
                exe1_zero_extend<=1'b0;
                exe1_rdram_need_zero_extend<=1'b0;
                exe1_rdram_need_signed_extend<=1'b0;
                exe1_rdram_num<=2'b0;
                exe1_wdram_num<=2'b0;
                exe1_csr_num<=14'b0;
                exe1_csr_we<=1'b0;
                exe1_is_ertn<=1'b0;
                exe1_is_syscall<=1'b0;
                exe1_res_from_csr<=1'b0;
                exe1_csr_wmask<=32'b0;
                exe1_csr_wdata<=32'b0;
                exe1_ex_adef<=1'b0;
                exe1_ex_ale_h<=1'b0;
                exe1_ex_ale_w<=1'b0;
                exe1_ex_brk<=1'b0;
                exe1_ex_ine<=1'b0;
                exe1_has_int<=1'b0;
                exe1_int_ecode<=6'b0;
                exe1_int_esubcode<=8'b0;
                exe1_rj<=5'b0;
                exe1_res_of_cnt<=32'b0;
                exe1_res_is_rj<=1'b0;
                exe1_res_from_cnt<=1'b0;
                exe1_res_from_tid<=1'b0;
                exe1_need_data_sram<=1'b0;
                exe1_need_cancel <= 1'b0;
                exe1_inst_tlbrd <= 1'b0;
                exe1_inst_tlbsrch <= 1'b0;
                exe1_tlb_wr_en <= 1'b0;
                exe1_tlb_we <= 1'b0;
                exe1_tlb_fill_en <= 1'b0;
                exe1_invtlb_asid <= 10'b0;
                exe1_invtlb_op <= 5'b0;
                exe1_invtlb_va <= 19'b0;
                exe1_invtlb_valid <= 1'b0;
                exe1_is_st <= 1'b0;
                exe1_is_ld <= 1'b0;
                exe1_tlb_or_csr_we <= 1'b0;
                exe1_inst_tlb_ex <= 2'b0;
                end
            end
            default: begin  // ready 或不确定时都更新
                exe1_rd <= id_rd;
                exe1_src1 <= id_src1;
                exe1_src2 <= id_src2;
                exe1_ref_we <= id_ref_we;
                exe1_alu_op <= id_alu_op;
                exe1_dram_re <= id_dram_re;
                exe1_dram_we <= id_dram_we;
                exe1_imm12 <= id_imm12;
                exe1_src2_is_imm12 <= id_src2_is_imm12;
                exe1_src2_is_imm5 <= id_src2_is_imm5;
                exe1_imm5 <= id_imm5;
                exe1_pc <= id_pc;
                exe1_imm16 <= id_imm16;
                exe1_imm26 <= id_imm26;
                exe1_src2_is_imm26 <= id_src2_is_imm26;
                exe1_src2_is_imm16 <= id_src2_is_imm16;
                exe1_res_from_dram <= id_res_from_dram;
                exe1_dram_wdata <= id_dram_wdata;
                exe1_imm20 <= id_imm20;
                exe1_src2_is_imm20 <= id_src2_is_imm20;
                exe1_rf_src1 <= id_src1;
                exe1_rf_src2 <= id_src2;
                exe1_zero_extend<=id_zero_extend;
                exe1_rdram_need_zero_extend<=id_rdram_need_zero_extend;
                exe1_rdram_need_signed_extend<=id_rdram_need_signed_extend;
                exe1_rdram_num<=id_rdram_num;
                exe1_wdram_num<=id_wdram_num;
                exe1_csr_num<=id_csr_num;
                exe1_csr_we<=id_csr_we;
                exe1_is_ertn<=id_is_ertn;
                exe1_is_syscall<=id_is_syscall;
                exe1_res_from_csr<=id_res_from_csr;
                exe1_csr_wmask<=id_csr_wmask;
                exe1_csr_wdata<=id_csr_wdata;
                exe1_ex_adef<=id_ex_adef;
                exe1_ex_ale_h<=id_ex_ale_h;
                exe1_ex_ale_w<=id_ex_ale_w;
                exe1_ex_brk<=id_ex_brk;
                exe1_ex_ine<=id_ex_ine;
                exe1_has_int<=id_has_int;
                exe1_int_ecode<=id_int_ecode;
                exe1_int_esubcode<=id_int_esubcode;
                exe1_rj<=id_rj;
                exe1_res_of_cnt<=id_res_of_cnt;
                exe1_res_is_rj<=id_res_is_rj;
                exe1_res_from_cnt<=id_res_from_cnt;
                exe1_res_from_tid<=id_res_from_tid;
                exe1_need_data_sram<=id_need_data_sram;
                exe1_need_cancel <= id_need_cancel;
                exe1_inst_tlbrd <= id_inst_tlbrd;
                exe1_inst_tlbsrch <= id_inst_tlbsrch;
                exe1_tlb_wr_en <= id_tlb_wr_en;
                exe1_tlb_we <= id_tlb_we;
                exe1_tlb_fill_en <= id_tlb_fill_en;
                exe1_invtlb_asid <= id_invtlb_asid;
                exe1_invtlb_op <= id_invtlb_op;
                exe1_invtlb_va <= id_invtlb_va;
                exe1_invtlb_valid <= id_invtlb_valid;
                exe1_is_st <= id_is_st;
                exe1_is_ld <= id_is_ld;
                exe1_tlb_or_csr_we <= id_tlb_or_csr_we;
                exe1_inst_tlb_ex <= id_inst_tlb_ex;
                exe1_inst <= id_inst;
                exe1_dropped <= 1'b0;
               //exe_csr_rdata<=id_csr_rdata;
            end
        endcase
    end
end


endmodule
