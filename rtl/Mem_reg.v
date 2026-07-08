module Mem_reg (
    input wire clk,
    input wire rst,
    input wire wb_ex,
    input wire wb_is_ertn,
    input wire exe2_ready_go,
    input wire mem_allow_in,
    input wire mem_data_shake_ok,
    input wire [31:0] exe2_alu_result,
    input wire exe2_ref_we,
    input wire exe2_dram_re,
    input wire exe2_dram_we,
    input wire [4:0] exe2_rd,
    input wire exe2_br_taken,
    input wire [31:0] exe2_br_target,
    input wire exe2_res_from_dram,
    input wire [31:0] exe2_dram_waddr,
    input wire [31:0] exe2_dram_wdata,
    input wire [31:0] exe2_pc,
    input wire [1:0] exe2_rdram_num,
    input wire exe2_rdram_need_signed_extend,
    input wire exe2_rdram_need_zero_extend,
    input wire [1:0]exe2_wdram_num,
    input wire [13:0] exe2_csr_num,
    input wire exe2_csr_we,
    input wire exe2_is_ertn,
    input wire exe2_is_syscall,
    input wire exe2_res_from_csr,
    input wire [31:0] exe2_csr_wmask,
    input wire [31:0] exe2_csr_wdata,
    input wire exe2_ex_adef,
    input wire exe2_ex_brk,
    input wire exe2_ex_ine,
    input wire exe2_ex_ale_h,
    input wire exe2_ex_ale_w,
    input wire exe2_ex_ale,
    input wire exe2_has_int,
    input wire [5:0] exe2_int_ecode,
    input wire [7:0] exe2_int_esubcode,
    input wire [4:0]exe2_rj,
    input wire [31:0]exe2_res_of_cnt,
    input wire exe2_res_is_rj,
    input wire exe2_res_from_cnt,
    input wire exe2_res_from_tid,
    input wire exe2_need_data_sram,
    input wire [31:0] exe2_data_addr,
    input wire [31:0] exe2_data_paddr,   // TLB/DMW 翻译后物理地址，仅供 difftest StoreEvent 上报
    input wire exe2_need_cancel,
    input wire exe2_inst_tlbrd,
    input wire exe2_inst_tlbsrch,
    input wire exe2_tlb_wr_en,
    input wire exe2_tlb_we,
    input wire exe2_tlb_fill_en,
    input wire [9:0] exe2_invtlb_asid,
    input wire [4:0] exe2_invtlb_op,
    input wire [18:0] exe2_invtlb_va,
    input wire exe2_invtlb_valid,
    input wire [4:0] exe2_alu_op,
    input wire exe2_tlb_or_csr_we,
    input wire [1:0]exe2_inst_tlb_ex,
    input wire [2:0]exe2_data_tlb_ex,
    input wire [31:0] exe2_inst,

    output reg mem_ref_we,
    output reg [31:0] mem_alu_result,
    output reg mem_dram_re,
    output reg mem_dram_we,
    output reg [4:0] mem_rd,
    output reg mem_br_taken,
    output reg [31:0] mem_br_target,
    output reg mem_res_from_dram,
    output reg [31:0] mem_dram_wdata,
    output reg [31:0] mem_dram_waddr,
    output reg [31:0] mem_pc,
    output reg [1:0] mem_rdram_num,
    output reg mem_rdram_need_signed_extend,
    output reg mem_rdram_need_zero_extend,
    output reg [1:0] mem_wdram_num,
    output reg [13:0] mem_csr_num,
    output reg mem_csr_we,
    output reg mem_is_ertn,
    output reg mem_is_syscall,
    output reg mem_res_from_csr,
    output reg [31:0] mem_csr_wmask,
    output reg [31:0] mem_csr_wdata,
    output reg mem_ex_adef,
    output reg mem_ex_brk,
    output reg mem_ex_ine,
    output reg mem_ex_ale_h,
    output reg mem_ex_ale_w,
    output reg mem_ex_ale,
    output reg mem_has_int,
    output reg [5:0] mem_int_ecode,
    output reg [7:0] mem_int_esubcode,
    output reg [4:0]mem_rj,
    output reg [31:0]mem_res_of_cnt,
    output reg mem_res_is_rj,
    output reg mem_res_from_cnt,
    output reg mem_res_from_tid,
    output reg mem_need_data_sram,
    output reg [31:0] mem_data_addr,
    output reg [31:0] mem_data_paddr,
    output reg mem_need_cancel,
    output reg mem_inst_tlbrd,
    output reg mem_inst_tlbsrch,
    output reg mem_tlb_wr_en,
    output reg mem_tlb_we,
    output reg mem_tlb_fill_en,
    output reg [9:0] mem_invtlb_asid,
    output reg [4:0] mem_invtlb_op,
    output reg [18:0] mem_invtlb_va,
    output reg mem_invtlb_valid,
    output reg [4:0] mem_alu_op,
    output reg mem_tlb_or_csr_we,
    output reg [1:0]mem_inst_tlb_ex,
    output reg [2:0]mem_data_tlb_ex,
    output reg [31:0] mem_inst
);

always @(posedge clk) begin
    // ERTN must NOT flush MEM: the delay slot instruction (in MEM when ERTN is in WB)
    // needs to commit before the PC redirect takes effect.
    if (rst||wb_ex===1'b1) begin
        mem_ref_we       <= 1'b0;
        mem_alu_result   <= 32'd0;
        mem_dram_re      <= 1'b0;
        mem_dram_we      <= 1'b0;
        mem_rd           <= 5'd0;
        mem_br_taken     <= 1'b0;
        mem_br_target    <= 32'd0;
        mem_res_from_dram<= 1'b0;
        mem_dram_wdata   <= 32'd0;
        mem_dram_waddr   <= 32'd0;
        mem_pc           <= 32'd0;
        mem_rdram_num <=2'b0;
     mem_rdram_need_signed_extend<=1'b0;
     mem_rdram_need_zero_extend<=1'b0;
        mem_wdram_num<=2'b0;
        mem_csr_num<=14'b0;
        mem_csr_we<=1'b0;
        mem_is_ertn<=1'b0;
        mem_is_syscall<=1'b0;
        mem_res_from_csr<=1'b0;
        mem_csr_wmask<=32'b0;
        mem_csr_wdata<=32'b0;
        mem_ex_adef<=1'b0;
        mem_ex_ale_h<=1'b0;
        mem_ex_ale_w<=1'b0;
        mem_ex_brk<=1'b0;
        mem_ex_ine<=1'b0;
        mem_has_int<=1'b0;
        mem_int_ecode<=6'b0;
        mem_int_esubcode<=8'b0;
        mem_rj<=5'b0;
        mem_res_of_cnt<=32'b0;
        mem_res_is_rj<=1'b0;
        mem_res_from_cnt<=1'b0;
        mem_ex_ale<=1'b0;
        mem_res_from_tid<=1'b0;
        mem_need_data_sram<=1'b0;
        mem_data_addr <= 32'b0;
        mem_data_paddr <= 32'b0;
        mem_need_cancel <= 1'b0;
        mem_inst_tlbrd <= 1'b0;
        mem_inst_tlbsrch <= 1'b0;
        mem_tlb_wr_en <= 1'b0;
        mem_tlb_we <= 1'b0;
        mem_tlb_fill_en <= 1'b0;
        mem_invtlb_asid <= 10'b0;
        mem_invtlb_op <= 5'b0;
        mem_invtlb_va <= 19'b0;
        mem_invtlb_valid <= 1'b0;
        mem_alu_op <= 5'b0;
        mem_tlb_or_csr_we <= 1'b0 ;
        mem_inst_tlb_ex <= 2'b0;
        mem_data_tlb_ex <= 3'b0;
        mem_inst <= 32'd0;

    end else begin
        casez ( !(exe2_ready_go===1'b0)&&mem_allow_in)
            1'b1:
            begin
                mem_ref_we       <= exe2_ref_we;
                mem_alu_result   <= exe2_alu_result;
                mem_dram_re      <= exe2_dram_re;
                mem_dram_we      <= exe2_dram_we;
                mem_rd           <= exe2_rd;
                mem_br_taken     <= exe2_br_taken;
                mem_br_target    <= exe2_br_target;
                mem_res_from_dram<= exe2_res_from_dram;
                mem_dram_wdata   <= exe2_dram_wdata;
                mem_dram_waddr   <= exe2_dram_waddr;
                mem_pc           <= exe2_pc;
                mem_rdram_num <=exe2_rdram_num;
                mem_rdram_need_signed_extend<=exe2_rdram_need_signed_extend;
                mem_rdram_need_zero_extend<=exe2_rdram_need_zero_extend;
                mem_wdram_num<=exe2_wdram_num;
                mem_csr_num<=exe2_csr_num;
                mem_csr_we<=exe2_csr_we;
                mem_is_ertn<=exe2_is_ertn;
                mem_is_syscall<=exe2_is_syscall;
                mem_res_from_csr<=exe2_res_from_csr;
                mem_csr_wmask<=exe2_csr_wmask;
                mem_csr_wdata<=exe2_csr_wdata;
                mem_ex_adef<=exe2_ex_adef;
                mem_ex_ale_h<=exe2_ex_ale_h;
                mem_ex_ale_w<=exe2_ex_ale_w;
                mem_ex_ale <= exe2_ex_ale;
                mem_ex_brk<=exe2_ex_brk;
                mem_ex_ine<=exe2_ex_ine;
                mem_has_int<=exe2_has_int;
                mem_int_ecode<=exe2_int_ecode;
                mem_int_esubcode<=exe2_int_esubcode;
                mem_rj<=exe2_rj;
                mem_res_of_cnt<=exe2_res_of_cnt;
                mem_res_is_rj<=exe2_res_is_rj;
                mem_res_from_cnt<=exe2_res_from_cnt;
                mem_res_from_tid<=exe2_res_from_tid;
                mem_need_data_sram<=exe2_need_data_sram;
                mem_data_addr <= exe2_data_addr;
                mem_data_paddr <= exe2_data_paddr;
                mem_need_cancel <= exe2_need_cancel;
                mem_inst_tlbrd <= exe2_inst_tlbrd;
                mem_inst_tlbsrch <= exe2_inst_tlbsrch;
                mem_tlb_wr_en <= exe2_tlb_wr_en;
                mem_tlb_we <= exe2_tlb_we;
                mem_tlb_fill_en <= exe2_tlb_fill_en;
                mem_invtlb_asid <= exe2_invtlb_asid;
                mem_invtlb_op <= exe2_invtlb_op;
                mem_invtlb_va <= exe2_invtlb_va;
                mem_invtlb_valid <= exe2_invtlb_valid;
                mem_alu_op <= exe2_alu_op;
                 mem_tlb_or_csr_we <= exe2_tlb_or_csr_we ;
                mem_inst_tlb_ex <= exe2_inst_tlb_ex;
                mem_data_tlb_ex <= exe2_data_tlb_ex;
                mem_inst <= exe2_inst;
            end
            1'b0: begin
                if(mem_data_shake_ok===1'b0)
                begin
                mem_ref_we       <= mem_ref_we   ;
                mem_alu_result   <= mem_alu_result;
                mem_dram_re      <= mem_dram_re;
                mem_dram_we      <= mem_dram_we;
                mem_rd           <= mem_rd;
                mem_br_taken     <= mem_br_taken;
                mem_br_target    <= mem_br_target;
                mem_res_from_dram<= mem_res_from_dram;
                mem_dram_wdata   <= mem_dram_wdata;
                mem_dram_waddr   <= mem_dram_waddr;
                mem_pc           <= mem_pc;
                mem_rdram_need_signed_extend<=mem_rdram_need_signed_extend;
                mem_rdram_need_zero_extend<=mem_rdram_need_zero_extend;
                mem_rdram_num <=mem_rdram_num;
                mem_wdram_num<=mem_wdram_num;
                mem_csr_num<=14'b0;
                mem_csr_num<=mem_csr_num;
                mem_csr_we<=mem_csr_we;
                mem_is_ertn<=mem_is_ertn;
                mem_is_syscall<=mem_is_syscall;
                mem_res_from_csr<=mem_res_from_csr;
                mem_csr_wmask<=mem_csr_wmask;
                mem_csr_wdata<=mem_csr_wdata;
                mem_ex_adef<=mem_ex_adef;
                mem_ex_ale_h<=mem_ex_ale_h;
                mem_ex_ale_w<=mem_ex_ale_w;
                mem_ex_brk<=mem_ex_brk;
                mem_ex_ine<=mem_ex_ine;
                mem_has_int<=mem_has_int;
                mem_int_ecode<=mem_int_ecode;
                mem_int_esubcode<=mem_int_esubcode;
                mem_rj<=mem_rj;
                mem_res_of_cnt<=mem_res_of_cnt;
                mem_res_is_rj<=mem_res_is_rj;
                mem_res_from_cnt<=mem_res_from_cnt;
                mem_ex_ale<=mem_ex_ale;
                mem_res_from_tid<=mem_res_from_tid;
                mem_need_data_sram<=mem_need_data_sram;
                mem_data_addr <= mem_data_addr;
                mem_data_paddr <= mem_data_paddr;
                mem_need_cancel <= mem_need_cancel;
                mem_inst_tlbrd <= mem_inst_tlbrd;
                mem_inst_tlbsrch <= mem_inst_tlbsrch;
                mem_tlb_wr_en <= mem_tlb_wr_en;
                mem_tlb_we <= mem_tlb_we;
                mem_tlb_fill_en <= mem_tlb_fill_en;
                mem_invtlb_asid <= mem_invtlb_asid;
                mem_invtlb_op <= mem_invtlb_op;
                mem_invtlb_va <= mem_invtlb_va;
                mem_invtlb_valid <= mem_invtlb_valid;
                mem_alu_op <= mem_alu_op;
                 mem_tlb_or_csr_we <= mem_tlb_or_csr_we ;
                mem_inst_tlb_ex <= mem_inst_tlb_ex;
                mem_data_tlb_ex <= mem_data_tlb_ex;
                mem_inst <= mem_inst;
                end
                else if(exe2_ready_go===1'b0)
                begin
                mem_ref_we       <= 1'b0;
                mem_alu_result   <= 32'd0;
                mem_dram_re      <= 1'b0;
                mem_dram_we      <= 1'b0;
                mem_rd           <= 5'd0;
                mem_br_taken     <= 1'b0;
                mem_br_target    <= 32'd0;
                mem_res_from_dram<= 1'b0;
                mem_dram_wdata   <= 32'd0;
                mem_dram_waddr   <= 32'd0;
                mem_pc           <= 32'd0;
                mem_rdram_num <=2'b0;
                mem_rdram_need_signed_extend<=1'b0;
                mem_rdram_need_zero_extend<=1'b0;
                mem_wdram_num<=2'b0;
                mem_csr_num<=14'b0;
                mem_csr_we<=1'b0;
                mem_is_ertn<=1'b0;
                mem_is_syscall<=1'b0;
                mem_res_from_csr<=1'b0;
                mem_csr_wmask<=32'b0;
                mem_csr_wdata<=32'b0;
                mem_ex_adef<=1'b0;
                mem_ex_ale_h<=1'b0;
                mem_ex_ale_w<=1'b0;
                mem_ex_brk<=1'b0;
                mem_ex_ine<=1'b0;
                mem_has_int<=1'b0;
                mem_int_ecode<=6'b0;
                mem_int_esubcode<=8'b0;
                mem_rj<=5'b0;
                mem_res_of_cnt<=32'b0;
                mem_res_is_rj<=1'b0;
                mem_res_from_cnt<=1'b0;
                mem_ex_ale<=1'b0;
                mem_res_from_tid<=1'b0;
                mem_need_data_sram<=1'b0;
                mem_data_addr <= 32'b0;
                mem_data_paddr <= 32'b0;
                mem_need_cancel <= 1'b0;
                mem_inst_tlbrd <= 1'b0;
                mem_inst_tlbsrch <= 1'b0;
                mem_tlb_wr_en <= 1'b0;
                mem_tlb_we <= 1'b0;
                mem_tlb_fill_en <= 1'b0;
                mem_invtlb_asid <= 10'b0;
                mem_invtlb_op <= 5'b0;
                mem_invtlb_va <= 19'b0;
                mem_invtlb_valid <= 1'b0;
                mem_alu_op <= 5'b0;
                 mem_tlb_or_csr_we <= 1'b0 ;
                mem_inst_tlb_ex <= 2'b0;
                mem_data_tlb_ex <= 3'b0;
                mem_inst <= 32'd0;
                end
                else
                begin
                mem_ref_we       <= mem_ref_we   ;
                mem_alu_result   <= mem_alu_result;
                mem_dram_re      <= mem_dram_re;
                mem_dram_we      <= mem_dram_we;
                mem_rd           <= mem_rd;
                mem_br_taken     <= mem_br_taken;
                mem_br_target    <= mem_br_target;
                mem_res_from_dram<= mem_res_from_dram;
                mem_dram_wdata   <= mem_dram_wdata;
                mem_dram_waddr   <= mem_dram_waddr;
                mem_pc           <= mem_pc;
                mem_rdram_need_signed_extend<=mem_rdram_need_signed_extend;
                mem_rdram_need_zero_extend<=mem_rdram_need_zero_extend;
                 mem_rdram_num <=mem_rdram_num;
                 mem_wdram_num<=mem_wdram_num;
                 mem_csr_num<=14'b0;
                 mem_csr_num<=mem_csr_num;
                mem_csr_we<=mem_csr_we;
                mem_is_ertn<=mem_is_ertn;
                mem_is_syscall<=mem_is_syscall;
                mem_res_from_csr<=mem_res_from_csr;
                mem_csr_wmask<=mem_csr_wmask;
                mem_csr_wdata<=mem_csr_wdata;
                mem_ex_adef<=mem_ex_adef;
                mem_ex_ale_h<=mem_ex_ale_h;
                mem_ex_ale_w<=mem_ex_ale_w;
                mem_ex_brk<=mem_ex_brk;
                mem_ex_ine<=mem_ex_ine;
                mem_has_int<=mem_has_int;
                mem_int_ecode<=mem_int_ecode;
                mem_int_esubcode<=mem_int_esubcode;
                mem_rj<=mem_rj;
                mem_res_of_cnt<=mem_res_of_cnt;
                mem_res_is_rj<=mem_res_is_rj;
                mem_res_from_cnt<=mem_res_from_cnt;
                mem_ex_ale<=mem_ex_ale;
                mem_res_from_tid<=mem_res_from_tid;
                mem_need_data_sram<=mem_need_data_sram;
                mem_data_addr <= mem_data_addr;
                mem_data_paddr <= mem_data_paddr;
                mem_need_cancel <= mem_need_cancel;
                mem_inst_tlbrd <= mem_inst_tlbrd;
                mem_inst_tlbsrch <= mem_inst_tlbsrch;
                mem_tlb_wr_en <= mem_tlb_wr_en;
                mem_tlb_we <= mem_tlb_we;
                mem_tlb_fill_en <= mem_tlb_fill_en;
                mem_invtlb_asid <= mem_invtlb_asid;
                mem_invtlb_op <= mem_invtlb_op;
                mem_invtlb_va <= mem_invtlb_va;
                mem_invtlb_valid <= mem_invtlb_valid;
                mem_alu_op <= mem_alu_op;
                 mem_tlb_or_csr_we <= mem_tlb_or_csr_we ;
                mem_inst_tlb_ex <= mem_inst_tlb_ex;
                mem_data_tlb_ex <= mem_data_tlb_ex;
                mem_inst <= mem_inst;
                end

            end
            default :
            begin
                mem_ref_we       <= exe2_ref_we;
                mem_alu_result   <= exe2_alu_result;
                mem_dram_re      <= exe2_dram_re;
                mem_dram_we      <= exe2_dram_we;
                mem_rd           <= exe2_rd;
                mem_br_taken     <= exe2_br_taken;
                mem_br_target    <= exe2_br_target;
                mem_res_from_dram<= exe2_res_from_dram;
                mem_dram_wdata   <= exe2_dram_wdata;
                mem_dram_waddr   <= exe2_dram_waddr;
                mem_pc           <= exe2_pc;
                mem_rdram_num <=exe2_rdram_num;
                mem_rdram_need_signed_extend<=exe2_rdram_need_signed_extend;
                mem_rdram_need_zero_extend<=exe2_rdram_need_zero_extend;
                mem_wdram_num<=exe2_wdram_num;
                mem_csr_num<=exe2_csr_num;
                mem_csr_we<=exe2_csr_we;
                mem_is_ertn<=exe2_is_ertn;
                mem_is_syscall<=exe2_is_syscall;
                mem_res_from_csr<=exe2_res_from_csr;
                mem_csr_wmask<=exe2_csr_wmask;
                mem_csr_wdata<=exe2_csr_wdata;
                mem_ex_adef<=exe2_ex_adef;
                mem_ex_ale_h<=exe2_ex_ale_h;
                mem_ex_ale_w<=exe2_ex_ale_w;
                mem_ex_ale <= exe2_ex_ale;
                mem_ex_brk<=exe2_ex_brk;
                mem_ex_ine<=exe2_ex_ine;
                mem_has_int<=exe2_has_int;
                mem_int_ecode<=exe2_int_ecode;
                mem_int_esubcode<=exe2_int_esubcode;
                mem_rj<=exe2_rj;
                mem_res_of_cnt<=exe2_res_of_cnt;
                mem_res_is_rj<=exe2_res_is_rj;
                mem_res_from_cnt<=exe2_res_from_cnt;
                mem_res_from_tid<=exe2_res_from_tid;
                mem_need_data_sram<=exe2_need_data_sram;
                mem_data_addr <= exe2_data_addr;
                mem_data_paddr <= exe2_data_paddr;
                mem_need_cancel <= exe2_need_cancel;
                mem_inst_tlbrd <= exe2_inst_tlbrd;
                mem_inst_tlbsrch <= exe2_inst_tlbsrch;
                mem_tlb_wr_en <= exe2_tlb_wr_en;
                mem_tlb_we <= exe2_tlb_we;
                mem_tlb_fill_en <= exe2_tlb_fill_en;
                mem_invtlb_asid <= exe2_invtlb_asid;
                mem_invtlb_op <= exe2_invtlb_op;
                mem_invtlb_va <= exe2_invtlb_va;
                mem_invtlb_valid <= exe2_invtlb_valid;
                mem_alu_op <= exe2_alu_op;
                 mem_tlb_or_csr_we <= exe2_tlb_or_csr_we ;
                mem_inst_tlb_ex <= exe2_inst_tlb_ex;
                mem_data_tlb_ex <= exe2_data_tlb_ex;
                mem_inst <= exe2_inst;
            end
        endcase
    end
end

endmodule
