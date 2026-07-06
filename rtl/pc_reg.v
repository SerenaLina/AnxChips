module PC_Reg(
    input wire clk,
    input wire rst,
    input wire wb_ready_go,
    input wire pc_br_taken,
    input wire if_allow_in,
    input wire [31:0] pc_br_target,
    input wire pre_if_ready_go,
    input wire pipline_is_not_stalled,
    input wire wb_ex,
    input wire [1:0] inst_tlb_ex,
    input wire btb_hit,              // BTB predicted taken
    input wire [31:0] btb_target,    // BTB predicted target
    input wire wb_is_ertn,           // ERTN at WB: immediate PC redirect
    input wire [31:0] csr_era_pc,    // ERTN return address
    output reg [31:0] if_pc,
    output wire inst_en,
    output wire [31:0] inst_addr,
    output reg [1:0] if_inst_tlb_ex
);

    reg [31:0]nextpc;
    assign inst_en = rst? 1'b0 : 1'b1;

    assign inst_addr = nextpc;

    always @(posedge clk) begin
    if (inst_en == 0) begin
        if_pc <= 32'h1bfffffc;
        nextpc <= if_pc+4;
        if_inst_tlb_ex <= 2'b0;
    end
    else if (wb_is_ertn) begin
        if_pc <= csr_era_pc;
        nextpc <= csr_era_pc;
        if_inst_tlb_ex <= 2'b0;
    end else if (wb_ex) begin
        if_pc <= pc_br_target;
        nextpc <= pc_br_target;
        if_inst_tlb_ex <= 2'b0;
    // Branch redirect taken outside casez(if_allow_in) so it fires even
    // when IF is stalled (if_allow_in=0).  Under RUN_PERF_TEST the long
    // R-delay makes if_allow_in stay 0 for many cycles; a one-cycle
    // pc_br_taken pulse would be missed, causing PC to advance past the
    // branch into invalid padding and raise spurious INE exceptions.
    end else if (pc_br_taken && pipline_is_not_stalled) begin
        if_pc <= nextpc;
        nextpc <= pc_br_target;
        if_inst_tlb_ex <= inst_tlb_ex;
    end else begin
        casez (!(pre_if_ready_go===1'b0)&&if_allow_in)
            1'b1:
            begin
            if_pc <= nextpc;
            nextpc <= btb_hit ? btb_target : nextpc + 32'd4;
            if_inst_tlb_ex <= inst_tlb_ex;
            end
            1'b0:
            begin
            if_pc <= if_pc;
            nextpc <= nextpc;
            if_inst_tlb_ex <= if_inst_tlb_ex;
            end
            default:
            begin
            if_pc <= nextpc;
            nextpc <= btb_hit ? btb_target : nextpc + 32'd4;
            if_inst_tlb_ex <= inst_tlb_ex;
            end
        endcase
    end
end

endmodule
