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

    reg [3:0] state;
    reg [7:0] req_index;
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
    reg req_victim_valid;
    reg req_victim_dirty;
    reg [19:0] req_victim_tag;
    reg [127:0] req_victim_line;
    reg [1:0] beat;
    reg [31:0] resp_data;
    reg [31:0] mem_wdata_r;

    reg [255:0] valid0;
    reg [255:0] valid1;
    reg [255:0] dirty0;
    reg [255:0] dirty1;
    reg [255:0] used;

    wire ram_lookup = (state == S_IDLE) && req && (!uncached || is_cacop);
    wire [7:0] lookup_index = index;

    wire [31:0] data0_word0;
    wire [31:0] data0_word1;
    wire [31:0] data0_word2;
    wire [31:0] data0_word3;
    wire [31:0] data1_word0;
    wire [31:0] data1_word1;
    wire [31:0] data1_word2;
    wire [31:0] data1_word3;
    wire [19:0] tag0_dout;
    wire [19:0] tag1_dout;

    wire [127:0] data0_line = {data0_word3, data0_word2, data0_word1, data0_word0};
    wire [127:0] data1_line = {data1_word3, data1_word2, data1_word1, data1_word0};

    wire hit0 = valid0[req_index] && tag0_dout == req_paddr[31:12];
    wire hit1 = valid1[req_index] && tag1_dout == req_paddr[31:12];
    wire hit = hit0 || hit1;
    wire hit_way = hit1;
    wire replace_way = valid0[req_index] == 1'b0 ? 1'b0 :
                       valid1[req_index] == 1'b0 ? 1'b1 : ~used[req_index];
    wire victim_valid = replace_way ? valid1[req_index] : valid0[req_index];
    wire victim_dirty = replace_way ? dirty1[req_index] : dirty0[req_index];
    wire [19:0] victim_tag = replace_way ? tag1_dout : tag0_dout;
    wire [127:0] victim_line = replace_way ? data1_line : data0_line;

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

    wire [127:0] hit_line = hit_way ? data1_line : data0_line;
    wire [31:0] hit_word = select_word(hit_line, req_word);
    wire [31:0] hit_store_word = merge_word(hit_word, req_wdata, req_wstrb);
    wire [31:0] refill_write_word = (req_op && beat == req_word) ? merge_word(mem_rdata, req_wdata, req_wstrb) : mem_rdata;

    wire lookup_store_hit = (state == S_LOOKUP) && !req_is_cacop && hit && req_op;
    wire refill_write = (state == S_REF_WAIT) && mem_data_ok;
    wire tag_write = refill_write && (beat == 2'd3);

    wire [7:0] data_addr = (lookup_store_hit || refill_write) ? req_index : lookup_index;
    wire [7:0] tag_addr = tag_write ? req_index : lookup_index;
    wire [31:0] bank_dina = lookup_store_hit ? req_wdata : refill_write_word;

    wire store_way0 = lookup_store_hit && !hit_way;
    wire store_way1 = lookup_store_hit &&  hit_way;
    wire refill_way0 = refill_write && !req_way;
    wire refill_way1 = refill_write &&  req_way;

    wire [3:0] data0_we0 = (store_way0 && req_word == 2'd0) ? req_wstrb :
                           (refill_way0 && beat == 2'd0)   ? 4'hf : 4'h0;
    wire [3:0] data0_we1 = (store_way0 && req_word == 2'd1) ? req_wstrb :
                           (refill_way0 && beat == 2'd1)   ? 4'hf : 4'h0;
    wire [3:0] data0_we2 = (store_way0 && req_word == 2'd2) ? req_wstrb :
                           (refill_way0 && beat == 2'd2)   ? 4'hf : 4'h0;
    wire [3:0] data0_we3 = (store_way0 && req_word == 2'd3) ? req_wstrb :
                           (refill_way0 && beat == 2'd3)   ? 4'hf : 4'h0;
    wire [3:0] data1_we0 = (store_way1 && req_word == 2'd0) ? req_wstrb :
                           (refill_way1 && beat == 2'd0)   ? 4'hf : 4'h0;
    wire [3:0] data1_we1 = (store_way1 && req_word == 2'd1) ? req_wstrb :
                           (refill_way1 && beat == 2'd1)   ? 4'hf : 4'h0;
    wire [3:0] data1_we2 = (store_way1 && req_word == 2'd2) ? req_wstrb :
                           (refill_way1 && beat == 2'd2)   ? 4'hf : 4'h0;
    wire [3:0] data1_we3 = (store_way1 && req_word == 2'd3) ? req_wstrb :
                           (refill_way1 && beat == 2'd3)   ? 4'hf : 4'h0;

    mycpu_cache_data_bank_sram u_data0_bank0(
        .addra(data_addr), .clka(clk), .dina(bank_dina), .douta(data0_word0),
        .ena(1'b1), .wea(data0_we0)
    );
    mycpu_cache_data_bank_sram u_data0_bank1(
        .addra(data_addr), .clka(clk), .dina(bank_dina), .douta(data0_word1),
        .ena(1'b1), .wea(data0_we1)
    );
    mycpu_cache_data_bank_sram u_data0_bank2(
        .addra(data_addr), .clka(clk), .dina(bank_dina), .douta(data0_word2),
        .ena(1'b1), .wea(data0_we2)
    );
    mycpu_cache_data_bank_sram u_data0_bank3(
        .addra(data_addr), .clka(clk), .dina(bank_dina), .douta(data0_word3),
        .ena(1'b1), .wea(data0_we3)
    );
    mycpu_cache_data_bank_sram u_data1_bank0(
        .addra(data_addr), .clka(clk), .dina(bank_dina), .douta(data1_word0),
        .ena(1'b1), .wea(data1_we0)
    );
    mycpu_cache_data_bank_sram u_data1_bank1(
        .addra(data_addr), .clka(clk), .dina(bank_dina), .douta(data1_word1),
        .ena(1'b1), .wea(data1_we1)
    );
    mycpu_cache_data_bank_sram u_data1_bank2(
        .addra(data_addr), .clka(clk), .dina(bank_dina), .douta(data1_word2),
        .ena(1'b1), .wea(data1_we2)
    );
    mycpu_cache_data_bank_sram u_data1_bank3(
        .addra(data_addr), .clka(clk), .dina(bank_dina), .douta(data1_word3),
        .ena(1'b1), .wea(data1_we3)
    );

    mycpu_cache_tag_sram u_tag0(
        .addra(tag_addr), .clka(clk), .dina(req_paddr[31:12]), .douta(tag0_dout),
        .ena(1'b1), .wea(tag_write && !req_way)
    );
    mycpu_cache_tag_sram u_tag1(
        .addra(tag_addr), .clka(clk), .dina(req_paddr[31:12]), .douta(tag1_dout),
        .ena(1'b1), .wea(tag_write &&  req_way)
    );

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

    always @(posedge clk) begin
        if (!resetn) begin
            state <= S_IDLE;
            req_index <= 8'b0;
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
            req_victim_valid <= 1'b0;
            req_victim_dirty <= 1'b0;
            req_victim_tag <= 20'b0;
            req_victim_line <= 128'b0;
            beat <= 2'b0;
            resp_data <= 32'b0;
            mem_wdata_r <= 32'b0;
            valid0 <= 256'b0;
            valid1 <= 256'b0;
            dirty0 <= 256'b0;
            dirty1 <= 256'b0;
            used <= 256'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (req) begin
                        req_index <= index;
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

                        if (uncached && !is_cacop) begin
                            state <= S_UNC_REQ;
                        end else begin
                            state <= S_LOOKUP;
                        end
                    end
                end
                S_LOOKUP: begin
                    if (req_is_cacop) begin
                        if (req_cacop_code == 2'b10) begin
                            if (hit0) begin
                                req_way <= 1'b0;
                                req_victim_valid <= 1'b1;
                                req_victim_dirty <= dirty0[req_index];
                                req_victim_tag <= tag0_dout;
                                req_victim_line <= data0_line;
                                beat <= 2'b0;
                                mem_wdata_r <= data0_word0;
                                if (dirty0[req_index]) begin
                                    state <= S_WB_REQ;
                                end else begin
                                    valid0[req_index] <= 1'b0;
                                    dirty0[req_index] <= 1'b0;
                                    state <= S_CACOP_RESP;
                                end
                            end else if (hit1) begin
                                req_way <= 1'b1;
                                req_victim_valid <= 1'b1;
                                req_victim_dirty <= dirty1[req_index];
                                req_victim_tag <= tag1_dout;
                                req_victim_line <= data1_line;
                                beat <= 2'b0;
                                mem_wdata_r <= data1_word0;
                                if (dirty1[req_index]) begin
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
                            req_way <= req_cacop_way;
                            req_victim_valid <= req_cacop_way ? valid1[req_index] : valid0[req_index];
                            req_victim_dirty <= req_cacop_way ? dirty1[req_index] : dirty0[req_index];
                            req_victim_tag <= req_cacop_way ? tag1_dout : tag0_dout;
                            req_victim_line <= req_cacop_way ? data1_line : data0_line;
                            beat <= 2'b0;
                            mem_wdata_r <= req_cacop_way ? data1_word0 : data0_word0;
                            if (req_cacop_way == 1'b0 && valid0[req_index] && dirty0[req_index]) begin
                                state <= S_WB_REQ;
                            end else if (req_cacop_way == 1'b1 && valid1[req_index] && dirty1[req_index]) begin
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
                    end else if (hit) begin
                        resp_data <= req_op ? hit_store_word : hit_word;
                        if (hit_way == 1'b0) begin
                            dirty0[req_index] <= req_op ? 1'b1 : dirty0[req_index];
                        end else begin
                            dirty1[req_index] <= req_op ? 1'b1 : dirty1[req_index];
                        end
                        used[req_index] <= hit_way;
                        state <= S_HIT_RESP;
                    end else begin
                        req_way <= replace_way;
                        req_victim_valid <= victim_valid;
                        req_victim_dirty <= victim_dirty;
                        req_victim_tag <= victim_tag;
                        req_victim_line <= victim_line;
                        beat <= 2'b0;
                        mem_wdata_r <= select_word(victim_line, 2'd0);
                        if (victim_valid && victim_dirty) begin
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
                        state <= S_UNC_WAIT;
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
                            mem_wdata_r <= select_word(req_victim_line, beat + 2'd1);
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
                        if (beat == req_word) begin
                            resp_data <= refill_write_word;
                        end
                        if (beat == 2'd3) begin
                            if (req_way == 1'b0) begin
                                valid0[req_index] <= 1'b1;
                                dirty0[req_index] <= req_op;
                            end else begin
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
