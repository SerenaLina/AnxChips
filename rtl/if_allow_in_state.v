module if_allow_in_state (
    input wire clk,
    input wire rst,
    input wire pre_if_ready_go,
    input wire if_ready_go,
    input wire id_allow_in,
    input wire redirect,       // wb_ex || wb_is_ertn: force back to allow_in
    input wire data_ok,        // inst_sram_data_ok: data arrived, allow IF advance
    output wire if_allow_in
);
    parameter            allow_in   = 1'd1 ;
    parameter            not_allow_in  = 1'd0 ;

    reg st_cur;
    reg st_next;
    reg redirect_latched;

    always @(posedge clk)
    begin
        if(rst)
        begin
            st_cur <= allow_in;
            redirect_latched <= 1'b0;
        end
        else if(redirect)
        begin
            st_cur <= allow_in;
            redirect_latched <= 1'b1;
        end
        else if(redirect_latched && data_ok)
        begin
            st_cur <= allow_in;
            redirect_latched <= 1'b0;
        end
        else
        begin
            st_cur <= st_next;
        end
    end

    always @(*)
    begin
        case(st_cur)
            allow_in :
                if(redirect_latched || pre_if_ready_go===1'b0 || (!(pre_if_ready_go===1'b0)&& !(if_ready_go===1'b0) &&id_allow_in==1'b1))
                begin
                    st_next  = allow_in;
                end
                else
                begin
                    st_next  = not_allow_in;
                end
            not_allow_in:
                if((!(if_ready_go===1'b0)&&id_allow_in==1'b1))
                begin
                    st_next = allow_in;
                end
                else
                begin
                    st_next = not_allow_in;
                end
        endcase
    end

    assign if_allow_in = st_cur;
endmodule