module icache_two_way(
    input  wire        clk,
    input  wire        resetn,

    input  wire        fetch_req,
    input  wire [7:0]  fetch_index,
    input  wire [31:0] fetch_paddr,
    input  wire        fetch_uncached,
    output wire        fetch_addr_ok,
    output wire        fetch_data_ok,
    output wire [31:0] fetch_rdata,

    input  wire        cacop_req,
    input  wire [1:0]  cacop_code,
    input  wire [7:0]  cacop_index,
    input  wire [31:0] cacop_paddr,
    input  wire        cacop_way,
    output wire        cacop_addr_ok,
    output wire        cacop_data_ok,

    output wire        mem_req,
    output wire        mem_wr,
    output wire [1:0]  mem_size,
    output wire [3:0]  mem_wstrb,
    output wire [31:0] mem_addr,
    output wire [31:0] mem_wdata,
    input  wire        mem_addr_ok,
    input  wire        mem_data_ok,
    input  wire [31:0] mem_rdata
);
    localparam S_IDLE       = 3'd0;
    localparam S_HIT_RESP   = 3'd1;
    localparam S_UNC_REQ    = 3'd2;
    localparam S_UNC_WAIT   = 3'd3;
    localparam S_REF_REQ    = 3'd4;
    localparam S_REF_WAIT   = 3'd5;
    localparam S_REF_RESP   = 3'd6;
    localparam S_CACOP_RESP = 3'd7;

    reg [2:0] state;
    reg [7:0] req_index;
    reg [31:0] req_paddr;
    reg [1:0] req_word;
    reg req_uncached;
    reg req_replace_way;
    reg [1:0] refill_word;
    reg [127:0] refill_line;
    reg [31:0] resp_data;

    reg valid0 [0:255];
    reg valid1 [0:255];
    reg [19:0] tag0 [0:255];
    reg [19:0] tag1 [0:255];
    reg [127:0] data0 [0:255];
    reg [127:0] data1 [0:255];
    reg used [0:255];

    wire [19:0] fetch_tag = fetch_paddr[31:12];
    wire fetch_hit0 = valid0[fetch_index] && tag0[fetch_index] == fetch_tag;
    wire fetch_hit1 = valid1[fetch_index] && tag1[fetch_index] == fetch_tag;
    wire fetch_hit  = fetch_hit0 || fetch_hit1;
    wire fetch_hit_way = fetch_hit1;
    wire fetch_replace_way = valid0[fetch_index] == 1'b0 ? 1'b0 :
                             valid1[fetch_index] == 1'b0 ? 1'b1 : ~used[fetch_index];

    wire [19:0] cacop_tag = cacop_paddr[31:12];
    wire cacop_hit0 = valid0[cacop_index] && tag0[cacop_index] == cacop_tag;
    wire cacop_hit1 = valid1[cacop_index] && tag1[cacop_index] == cacop_tag;

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

    assign fetch_addr_ok = (state == S_IDLE) && !cacop_req && fetch_req;
    assign cacop_addr_ok = (state == S_IDLE) && cacop_req;
    assign fetch_data_ok = (state == S_HIT_RESP) || (state == S_UNC_WAIT && mem_data_ok) || (state == S_REF_RESP);
    assign cacop_data_ok = (state == S_CACOP_RESP);
    assign fetch_rdata = (state == S_UNC_WAIT && mem_data_ok) ? mem_rdata : resp_data;

    assign mem_req   = (state == S_UNC_REQ) || (state == S_REF_REQ);
    assign mem_wr    = 1'b0;
    assign mem_size  = 2'b10;
    assign mem_wstrb = 4'b0000;
    assign mem_wdata = 32'b0;
    assign mem_addr  = (state == S_REF_REQ) ? {req_paddr[31:4], refill_word, 2'b00} : req_paddr;

    integer i;
    always @(posedge clk) begin
        if (!resetn) begin
            state <= S_IDLE;
            req_index <= 8'b0;
            req_paddr <= 32'b0;
            req_word <= 2'b0;
            req_uncached <= 1'b0;
            req_replace_way <= 1'b0;
            refill_word <= 2'b0;
            refill_line <= 128'b0;
            resp_data <= 32'b0;
            for (i = 0; i < 256; i = i + 1) begin
                valid0[i] = 1'b0;
                valid1[i] = 1'b0;
                tag0[i] = 20'b0;
                tag1[i] = 20'b0;
                data0[i] = 128'b0;
                data1[i] = 128'b0;
                used[i] = 1'b0;
            end
        end else begin
            case (state)
                S_IDLE: begin
                    if (cacop_req) begin
                        if (cacop_code == 2'b10) begin
                            if (cacop_hit0) begin
                                valid0[cacop_index] <= 1'b0;
                            end
                            if (cacop_hit1) begin
                                valid1[cacop_index] <= 1'b0;
                            end
                        end else begin
                            if (cacop_way == 1'b0) begin
                                valid0[cacop_index] <= 1'b0;
                            end else begin
                                valid1[cacop_index] <= 1'b0;
                            end
                        end
                        state <= S_CACOP_RESP;
                    end else if (fetch_req) begin
                        req_index <= fetch_index;
                        req_paddr <= fetch_paddr;
                        req_word <= fetch_paddr[3:2];
                        req_uncached <= fetch_uncached;
                        req_replace_way <= fetch_replace_way;
                        refill_word <= 2'b0;
                        refill_line <= 128'b0;
                        if (fetch_uncached) begin
                            state <= S_UNC_REQ;
                        end else if (fetch_hit) begin
                            resp_data <= select_word(fetch_hit_way ? data1[fetch_index] : data0[fetch_index], fetch_paddr[3:2]);
                            used[fetch_index] <= fetch_hit_way;
                            state <= S_HIT_RESP;
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
                        state <= S_UNC_WAIT;
                    end
                end
                S_UNC_WAIT: begin
                    if (mem_data_ok) begin
                        resp_data <= mem_rdata;
                        state <= S_IDLE;
                    end
                end
                S_REF_REQ: begin
                    if (mem_addr_ok) begin
                        state <= S_REF_WAIT;
                    end
                end
                S_REF_WAIT: begin
                    if (mem_data_ok) begin
                        refill_line <= put_word(refill_line, refill_word, mem_rdata);
                        if (refill_word == 2'd3) begin
                            resp_data <= select_word(put_word(refill_line, refill_word, mem_rdata), req_word);
                            if (req_replace_way == 1'b0) begin
                                data0[req_index] <= put_word(refill_line, refill_word, mem_rdata);
                                tag0[req_index] <= req_paddr[31:12];
                                valid0[req_index] <= 1'b1;
                            end else begin
                                data1[req_index] <= put_word(refill_line, refill_word, mem_rdata);
                                tag1[req_index] <= req_paddr[31:12];
                                valid1[req_index] <= 1'b1;
                            end
                            used[req_index] <= req_replace_way;
                            state <= S_REF_RESP;
                        end else begin
                            refill_word <= refill_word + 2'd1;
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
