module ID_Reg (
    input wire clk,
    input wire rst,
    input wire if_ready_go,
    input wire id_inst_cancel,
    input wire exe_addr_shake_ok,
    input wire exe_data_ram_req,
    input wire exe_data_ram_addr_ok,
    input wire wb_is_ertn,
    input wire mem_is_ertn,
    input wire [31:0] if_pc,
    input wire [31:0] if_inst,
    input wire wb_ex,
    input wire pipline_is_not_stalled,
    input wire [1:0]id_need_cancel,
    input wire id_allow_in,
    input wire exe_allow_in,
    input wire [1:0] if_inst_tlb_ex,
    // 中断标记信号 - 来自interrupt.v
    input wire int_has_int,
    input wire [5:0] int_ecode,
    input wire [7:0] int_esubcode,
    output reg [31:0] id_pc,
    output reg [31:0] id_inst,
    output reg ID_need_cancel,
    output reg [1:0] id_inst_tlb_ex,
    // 中断标记信号输出到ID_stage
    output reg id_has_int,
    output reg [5:0] id_int_ecode,
    output reg [7:0] id_int_esubcode
);
    
    wire [31:0]if_to_id_inst;
    reg [31:0] if_to_id_inst_memory;
    reg        if_to_id_need_cancel_memory;  // buffered cancel flag
    reg        if_to_id_memory;
    wire [1:0] If_inst_tlb_ex;
    assign If_inst_tlb_ex = if_inst_tlb_ex & {2{id_need_cancel==2'b0}};

    always @(posedge clk)
    begin
        if(rst)
        begin
            if_to_id_inst_memory <= 32'b0;
            if_to_id_need_cancel_memory <= 1'b0;
            if_to_id_memory <= 1'b0;
        end
        else if((!(if_ready_go===1'b0)&&id_allow_in) || wb_ex === 1'b1 )
        begin
            if_to_id_memory <= 1'b0 ;
        end
        else if(!(if_ready_go===1'b0) && id_allow_in==1'b0 && if_to_id_memory==1'b0 && (id_need_cancel == 2'b00))
        begin
            if_to_id_inst_memory <= if_to_id_inst;
            if_to_id_need_cancel_memory <= (id_need_cancel != 2'b0);
            if_to_id_memory <= 1'b1;
        end
    end

    // Only STATE_NOT_NORMAL_two (2) cancels; STATE_NOT_NORMAL_one (1) lets target pass.
    assign if_to_id_inst = (id_need_cancel == 2'b10) ? 32'h02800000 : if_inst;

    // Effective cancel flag: state=2 only
    wire id_need_cancel_eff;
    assign id_need_cancel_eff = if_to_id_memory ? if_to_id_need_cancel_memory : (id_need_cancel == 2'b10);
    always @(posedge clk) begin
    if (rst || wb_ex===1'b1||wb_is_ertn===1'b1||mem_is_ertn===1'b1) begin
        id_pc   <= 32'h1bfffffc;
        id_inst <= 32'h0;
        ID_need_cancel <= 1'b0;
        id_inst_tlb_ex <= 2'b0;
        id_has_int <= 1'b0;
        id_int_ecode <= 6'b0;
        id_int_esubcode <= 8'b0;
    end
    else begin
        casez (!(if_ready_go===1'b0)&&id_allow_in)
            1'b1: begin
                id_pc   <= if_pc;
                id_inst <= id_inst_cancel? 32'h02800000:
                           if_to_id_memory ? if_to_id_inst_memory : if_to_id_inst;
                ID_need_cancel <= id_need_cancel_eff;
                id_inst_tlb_ex <= If_inst_tlb_ex;
                id_has_int <= int_has_int;
                id_int_ecode <= int_ecode;
                id_int_esubcode <= int_esubcode;
            end
            1'b0: begin
                if(exe_addr_shake_ok===1'b0)
                begin
                    id_pc <= id_pc;
                    id_inst <= id_inst;
                    ID_need_cancel <= ID_need_cancel;
                    id_inst_tlb_ex <= id_inst_tlb_ex;
                    id_has_int <= id_has_int;
                    id_int_ecode <= id_int_ecode;
                    id_int_esubcode <= id_int_esubcode;
                end
                else if(exe_allow_in==1'b0)
                begin
                    id_pc <= id_pc;
                    id_inst <= id_inst;
                    ID_need_cancel <= ID_need_cancel;
                    id_inst_tlb_ex <= id_inst_tlb_ex;
                    id_has_int <= id_has_int;
                    id_int_ecode <= id_int_ecode;
                    id_int_esubcode <= id_int_esubcode;
                end
                else if(exe_data_ram_req && exe_data_ram_addr_ok)
                begin
                    id_pc <= id_pc;
                    id_inst <= id_inst;
                    ID_need_cancel <= ID_need_cancel;
                    id_inst_tlb_ex <= id_inst_tlb_ex;
                    id_has_int <= id_has_int;
                    id_int_ecode <= id_int_ecode;
                    id_int_esubcode <= id_int_esubcode;
                end
                else if(pipline_is_not_stalled===1'b1)
                begin
                    id_pc <= 32'b0;
                    id_inst <=32'h02800000;
                    ID_need_cancel <= 1'b0;
                    id_inst_tlb_ex <= 2'b0;
                    id_has_int <= 1'b0;
                    id_int_ecode <= 6'b0;
                    id_int_esubcode <= 8'b0;
                end
                else
                begin
                    id_pc   <= id_pc;
                    id_inst <= id_inst;
                    ID_need_cancel <= ID_need_cancel;
                    id_inst_tlb_ex <= id_inst_tlb_ex;
                    id_has_int <= id_has_int;
                    id_int_ecode <= id_int_ecode;
                    id_int_esubcode <= id_int_esubcode;
                end
            end
            default: begin
                id_pc   <= if_pc;
                id_inst <= id_inst_cancel? 32'h02800000:
                           if_to_id_memory ? if_to_id_inst_memory : if_to_id_inst;
                ID_need_cancel <= id_need_cancel_eff;
                id_inst_tlb_ex <= If_inst_tlb_ex;
                id_has_int <= int_has_int;
                id_int_ecode <= int_ecode;
                id_int_esubcode <= int_esubcode;
            end
        endcase
    end
end


endmodule
