module dcache_two_way(
    input  wire         clk,
    input  wire         resetn,

    input  wire         req,
    input  wire         op,
    input  wire [1:0]   size,
    input  wire [7:0]   index,
    input  wire [31:0]  paddr,
    input  wire [3:0]   wstrb,
    input  wire [31:0]  wdata,
    input  wire         uncached,
    input  wire         is_cacop,
    input  wire [1:0]   cacop_code,
    input  wire         cacop_way,

    output wire         addr_ok,
    output wire         data_ok,
    output wire [31:0]  rdata,

    output wire         mem_req,
    output wire         mem_wr,
    output wire [1:0]   mem_size,
    output wire [3:0]   mem_wstrb,
    output wire [31:0]  mem_addr,
    output wire [31:0]  mem_wdata,
    input  wire         mem_addr_ok,
    input  wire         mem_data_ok,
    input  wire [31:0]  mem_rdata
);
    localparam S_IDLE       = 4'd0;
    localparam S_LOOKUP     = 4'd1;
    localparam S_HIT_RESP   = 4'd2;
    localparam S_UNC_REQ    = 4'd3;
    localparam S_UNC_WAIT   = 4'd4;
    localparam S_WB_REQ     = 4'd5;
    localparam S_WB_WAIT    = 4'd6;
    localparam S_REF_REQ    = 4'd7;
    localparam S_REF_WAIT   = 4'd8;
    localparam S_REF_RESP   = 4'd9;
    localparam S_CACOP_RESP = 4'd10;

    localparam CACHE_INDEX_BITS = 8;
    localparam CACHE_LINES      = 1 << CACHE_INDEX_BITS;
    localparam CACHE_TAG_BITS   = 32 - 4 - CACHE_INDEX_BITS;

    reg [3:0] state;
    reg [CACHE_INDEX_BITS-1:0] req_index;
    reg [31:0] req_paddr;
    reg [1:0] req_word;
    reg req_op;
    reg [1:0] req_size;
    reg [3:0] req_wstrb;
    reg [31:0] req_wdata;
    reg req_uncached;
    reg req_is_cacop;
    reg [1:0] req_cacop_code;
    reg req_cacop_way;
    reg req_way;
    reg req_hit;
    reg req_hit_way;
    reg req_victim_valid;
    reg req_victim_dirty;
    reg [CACHE_TAG_BITS-1:0] req_victim_tag;
    reg [127:0] req_victim_line;
    reg [1:0] beat;
    reg [127:0] refill_line;
    reg [31:0] resp_data;
    reg [31:0] mem_wdata_r;
    reg [127:0] data0_r;
    reg [127:0] data1_r;

    wire [127:0] line_after_store_hit0;
    wire [127:0] line_after_store_hit1;
    wire [127:0] refill_line_after_store;

    reg valid0 [0:CACHE_LINES-1];
    reg valid1 [0:CACHE_LINES-1];
    reg dirty0 [0:CACHE_LINES-1];
    reg dirty1 [0:CACHE_LINES-1];
    reg [CACHE_TAG_BITS-1:0] tag0 [0:CACHE_LINES-1];
    reg [CACHE_TAG_BITS-1:0] tag1 [0:CACHE_LINES-1];
    (* ram_style = "block" *) reg [127:0] data0 [0:CACHE_LINES-1];
    (* ram_style = "block" *) reg [127:0] data1 [0:CACHE_LINES-1];
    reg used [0:CACHE_LINES-1];

    wire [CACHE_INDEX_BITS-1:0] index_l = index[CACHE_INDEX_BITS-1:0];
    wire [CACHE_TAG_BITS-1:0] req_tag_now = req_paddr[31:CACHE_INDEX_BITS+4];
    wire hit0_now = valid0[req_index] && tag0[req_index] == req_tag_now;
    wire hit1_now = valid1[req_index] && tag1[req_index] == req_tag_now;
    wire hit_now = hit0_now || hit1_now;
    wire hit_way_now = hit1_now;
    wire replace_way_now = valid0[req_index] == 1'b0 ? 1'b0 :
                           valid1[req_index] == 1'b0 ? 1'b1 : ~used[req_index];
    wire victim_valid_now = replace_way_now ? valid1[req_index] : valid0[req_index];
    wire victim_dirty_now = replace_way_now ? dirty1[req_index] : dirty0[req_index];
    wire [CACHE_TAG_BITS-1:0] victim_tag_now = replace_way_now ? tag1[req_index] : tag0[req_index];
    wire [127:0] victim_line_now = replace_way_now ? data1_r : data0_r;

    function [31:0] select_word;
        input [127:0] line;
        input [1:0] word;
        begin
            case (word)
                2'd0: select_word = line[31:0];
                2'd1: select_word = line[63:32];
                2'd2: select_word = line[95:64];
                default: select_word = line[127:96];
            endcase
        end
    endfunction

    function [127:0] put_word;
        input [127:0] line;
        input [1:0] word;
        input [31:0] data;
        begin
            put_word = line;
            case (word)
                2'd0: put_word[31:0] = data;
                2'd1: put_word[63:32] = data;
                2'd2: put_word[95:64] = data;
                default: put_word[127:96] = data;
            endcase
        end
    endfunction

    function [31:0] merge_word;
        input [31:0] old_word;
        input [31:0] new_word;
        input [3:0] strb;
        begin
            merge_word[7:0]   = strb[0] ? new_word[7:0]   : old_word[7:0];
            merge_word[15:8]  = strb[1] ? new_word[15:8]  : old_word[15:8];
            merge_word[23:16] = strb[2] ? new_word[23:16] : old_word[23:16];
            merge_word[31:24] = strb[3] ? new_word[31:24] : old_word[31:24];
        end
    endfunction

    function [127:0] merge_line_store;
        input [127:0] line;
        input [1:0] word;
        input [31:0] data;
        input [3:0] strb;
        reg [31:0] old_word;
        reg [31:0] new_word;
        begin
            old_word = select_word(line, word);
            new_word = merge_word(old_word, data, strb);
            merge_line_store = put_word(line, word, new_word);
        end
    endfunction

    assign addr_ok = (state == S_IDLE) && req;
    assign data_ok = (state == S_HIT_RESP) || (state == S_UNC_WAIT && mem_data_ok) ||
                     (state == S_REF_RESP) || (state == S_CACOP_RESP);
    assign rdata = (state == S_UNC_WAIT && mem_data_ok) ? mem_rdata : resp_data;

    assign mem_req = (state == S_UNC_REQ) || (state == S_WB_REQ) || (state == S_REF_REQ);
    assign mem_wr  = (state == S_UNC_REQ) ? req_op : (state == S_WB_REQ);
    assign mem_size = (state == S_UNC_REQ) ? req_size : 2'b10;
    assign mem_wstrb = (state == S_UNC_REQ) ? req_wstrb : 4'b1111;
    assign mem_addr = (state == S_UNC_REQ) ? req_paddr :
                      (state == S_WB_REQ)  ? {req_victim_tag, req_index, beat, 2'b00} :
                                             {req_paddr[31:4], beat, 2'b00};
    assign mem_wdata = (state == S_UNC_REQ) ? req_wdata : mem_wdata_r;

    assign line_after_store_hit0 = merge_line_store(data0_r, req_word, req_wdata, req_wstrb);
    assign line_after_store_hit1 = merge_line_store(data1_r, req_word, req_wdata, req_wstrb);
    assign refill_line_after_store = req_op ? merge_line_store(put_word(refill_line, beat, mem_rdata), req_word, req_wdata, req_wstrb)
                                            : put_word(refill_line, beat, mem_rdata);

    integer i;
    always @(posedge clk) begin
        if (!resetn) begin
            state <= S_IDLE;
            req_index <= {CACHE_INDEX_BITS{1'b0}};
            req_paddr <= 32'b0;
            req_word <= 2'b0;
            req_op <= 1'b0;
            req_size <= 2'b0;
            req_wstrb <= 4'b0;
            req_wdata <= 32'b0;
            req_uncached <= 1'b0;
            req_is_cacop <= 1'b0;
            req_cacop_code <= 2'b0;
            req_cacop_way <= 1'b0;
            req_way <= 1'b0;
            req_hit <= 1'b0;
            req_hit_way <= 1'b0;
            req_victim_valid <= 1'b0;
            req_victim_dirty <= 1'b0;
            req_victim_tag <= {CACHE_TAG_BITS{1'b0}};
            req_victim_line <= 128'b0;
            beat <= 2'b0;
            refill_line <= 128'b0;
            resp_data <= 32'b0;
            mem_wdata_r <= 32'b0;
            data0_r <= 128'b0;
            data1_r <= 128'b0;
            for (i = 0; i < CACHE_LINES; i = i + 1) begin
                valid0[i] = 1'b0;
                valid1[i] = 1'b0;
                dirty0[i] = 1'b0;
                dirty1[i] = 1'b0;
                tag0[i] = {CACHE_TAG_BITS{1'b0}};
                tag1[i] = {CACHE_TAG_BITS{1'b0}};
                used[i] = 1'b0;
            end
        end else begin
            case (state)
                S_IDLE: begin
                    if (req) begin
                        req_index <= index_l;
                        req_paddr <= paddr;
                        req_word <= paddr[3:2];
                        req_op <= op;
                        req_size <= size;
                        req_wstrb <= wstrb;
                        req_wdata <= wdata;
                        req_uncached <= uncached;
                        req_is_cacop <= is_cacop;
                        req_cacop_code <= cacop_code;
                        req_cacop_way <= cacop_way;
                        beat <= 2'b0;
                        refill_line <= 128'b0;
                        data0_r <= data0[index_l];
                        data1_r <= data1[index_l];

                        if (uncached) begin
                            state <= S_UNC_REQ;
                        end else begin
                            state <= S_LOOKUP;
                        end
                    end
                end
                S_LOOKUP: begin
                    req_way <= req_is_cacop && req_cacop_code != 2'b10 ? req_cacop_way : (hit_now ? hit_way_now : replace_way_now);
                    req_hit <= hit_now;
                    req_hit_way <= hit_way_now;
                    req_victim_valid <= victim_valid_now;
                    req_victim_dirty <= victim_dirty_now;
                    req_victim_tag <= victim_tag_now;
                    req_victim_line <= victim_line_now;

                    if (req_is_cacop) begin
                        if (req_cacop_code == 2'b10) begin
                            if (hit0_now) begin
                                if (dirty0[req_index]) begin
                                    req_way <= 1'b0;
                                    req_victim_valid <= 1'b1;
                                    req_victim_dirty <= 1'b1;
                                    req_victim_tag <= tag0[req_index];
                                    req_victim_line <= data0_r;
                                    beat <= 2'b0;
                                    mem_wdata_r <= data0_r[31:0];
                                    state <= S_WB_REQ;
                                end else begin
                                    valid0[req_index] <= 1'b0;
                                    dirty0[req_index] <= 1'b0;
                                    state <= S_CACOP_RESP;
                                end
                            end else if (hit1_now) begin
                                if (dirty1[req_index]) begin
                                    req_way <= 1'b1;
                                    req_victim_valid <= 1'b1;
                                    req_victim_dirty <= 1'b1;
                                    req_victim_tag <= tag1[req_index];
                                    req_victim_line <= data1_r;
                                    beat <= 2'b0;
                                    mem_wdata_r <= data1_r[31:0];
                                    state <= S_WB_REQ;
                                end else begin
                                    valid1[req_index] <= 1'b0;
                                    dirty1[req_index] <= 1'b0;
                                    state <= S_CACOP_RESP;
                                end
                            end else begin
                                state <= S_CACOP_RESP;
                            end
                        end else if (req_cacop_code == 2'b01) begin
                            if (req_cacop_way == 1'b0 && valid0[req_index] && dirty0[req_index]) begin
                                req_way <= 1'b0;
                                req_victim_valid <= 1'b1;
                                req_victim_dirty <= 1'b1;
                                req_victim_tag <= tag0[req_index];
                                req_victim_line <= data0_r;
                                beat <= 2'b0;
                                mem_wdata_r <= data0_r[31:0];
                                state <= S_WB_REQ;
                            end else if (req_cacop_way == 1'b1 && valid1[req_index] && dirty1[req_index]) begin
                                req_way <= 1'b1;
                                req_victim_valid <= 1'b1;
                                req_victim_dirty <= 1'b1;
                                req_victim_tag <= tag1[req_index];
                                req_victim_line <= data1_r;
                                beat <= 2'b0;
                                mem_wdata_r <= data1_r[31:0];
                                state <= S_WB_REQ;
                            end else begin
                                if (req_cacop_way == 1'b0) begin
                                    valid0[req_index] <= 1'b0;
                                    dirty0[req_index] <= 1'b0;
                                end else begin
                                    valid1[req_index] <= 1'b0;
                                    dirty1[req_index] <= 1'b0;
                                end
                                state <= S_CACOP_RESP;
                            end
                        end else begin
                            if (req_cacop_way == 1'b0) begin
                                valid0[req_index] <= 1'b0;
                                dirty0[req_index] <= 1'b0;
                            end else begin
                                valid1[req_index] <= 1'b0;
                                dirty1[req_index] <= 1'b0;
                            end
                            state <= S_CACOP_RESP;
                        end
                    end else if (hit_now) begin
                        if (req_op) begin
                            if (hit_way_now == 1'b0) begin
                                data0[req_index] <= line_after_store_hit0;
                                dirty0[req_index] <= 1'b1;
                                resp_data <= select_word(line_after_store_hit0, req_word);
                            end else begin
                                data1[req_index] <= line_after_store_hit1;
                                dirty1[req_index] <= 1'b1;
                                resp_data <= select_word(line_after_store_hit1, req_word);
                            end
                        end else begin
                            resp_data <= select_word(hit_way_now ? data1_r : data0_r, req_word);
                        end
                        used[req_index] <= hit_way_now;
                        state <= S_HIT_RESP;
                    end else begin
                        if (victim_valid_now && victim_dirty_now) begin
                            beat <= 2'b0;
                            mem_wdata_r <= victim_line_now[31:0];
                            state <= S_WB_REQ;
                        end else begin
                            state <= S_REF_REQ;
                        end
                    end
                end
                S_HIT_RESP: begin
                    state <= S_IDLE;
                end
                S_UNC_REQ: begin
                    if (mem_addr_ok) begin
                        state <= req_op ? S_UNC_WAIT : S_UNC_WAIT;
                    end
                end
                S_UNC_WAIT: begin
                    if (mem_data_ok) begin
                        resp_data <= req_op ? 32'b0 : mem_rdata;
                        state <= S_IDLE;
                    end
                end
                S_WB_REQ: begin
                    if (mem_addr_ok) begin
                        state <= S_WB_WAIT;
                    end
                end
                S_WB_WAIT: begin
                    if (mem_data_ok) begin
                        if (beat == 2'd3) begin
                            if (req_is_cacop) begin
                                if (req_way == 1'b0) begin
                                    valid0[req_index] <= 1'b0;
                                    dirty0[req_index] <= 1'b0;
                                end else begin
                                    valid1[req_index] <= 1'b0;
                                    dirty1[req_index] <= 1'b0;
                                end
                                state <= S_CACOP_RESP;
                            end else begin
                                beat <= 2'b0;
                                state <= S_REF_REQ;
                            end
                        end else begin
                            beat <= beat + 2'd1;
                            case (beat + 2'd1)
                                2'd0: mem_wdata_r <= req_victim_line[31:0];
                                2'd1: mem_wdata_r <= req_victim_line[63:32];
                                2'd2: mem_wdata_r <= req_victim_line[95:64];
                                default: mem_wdata_r <= req_victim_line[127:96];
                            endcase
                            state <= S_WB_REQ;
                        end
                    end
                end
                S_REF_REQ: begin
                    if (mem_addr_ok) begin
                        state <= S_REF_WAIT;
                    end
                end
                S_REF_WAIT: begin
                    if (mem_data_ok) begin
                        refill_line <= put_word(refill_line, beat, mem_rdata);
                        if (beat == 2'd3) begin
                            resp_data <= select_word(refill_line_after_store, req_word);
                            if (req_way == 1'b0) begin
                                data0[req_index] <= refill_line_after_store;
                                tag0[req_index] <= req_paddr[31:CACHE_INDEX_BITS+4];
                                valid0[req_index] <= 1'b1;
                                dirty0[req_index] <= req_op;
                            end else begin
                                data1[req_index] <= refill_line_after_store;
                                tag1[req_index] <= req_paddr[31:CACHE_INDEX_BITS+4];
                                valid1[req_index] <= 1'b1;
                                dirty1[req_index] <= req_op;
                            end
                            used[req_index] <= req_way;
                            state <= S_REF_RESP;
                        end else begin
                            beat <= beat + 2'd1;
                            state <= S_REF_REQ;
                        end
                    end
                end
                S_REF_RESP: begin
                    state <= S_IDLE;
                end
                S_CACOP_RESP: begin
                    state <= S_IDLE;
                end
                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end
endmodule
