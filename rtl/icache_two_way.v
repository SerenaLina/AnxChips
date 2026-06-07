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
    localparam S_IDLE       = 4'd0;
    localparam S_LOOKUP     = 4'd1;
    localparam S_HIT_RESP   = 4'd2;
    localparam S_UNC_REQ    = 4'd3;
    localparam S_UNC_WAIT   = 4'd4;
    localparam S_REF_REQ    = 4'd5;
    localparam S_REF_WAIT   = 4'd6;
    localparam S_REF_RESP   = 4'd7;
    localparam S_CACOP_RESP = 4'd8;

    reg [3:0] state;
    reg [7:0] req_index;
    reg [31:0] req_paddr;
    reg [1:0] req_word;
    reg req_uncached;
    reg req_replace_way;
    reg req_is_cacop;
    reg [1:0] req_cacop_code;
    reg req_cacop_way;
    reg [1:0] refill_word;
    reg [31:0] resp_data;

    reg [255:0] valid0;
    reg [255:0] valid1;
    reg [255:0] used;

    wire ram_lookup = (state == S_IDLE) &&
                      (cacop_req || (fetch_req && !fetch_uncached));
    wire [7:0] lookup_index = cacop_req ? cacop_index : fetch_index;

    wire refill_write = (state == S_REF_WAIT) && mem_data_ok;
    wire tag_write = refill_write && (refill_word == 2'd3);
    wire [7:0] ram_addr = refill_write ? req_index : lookup_index;
    wire [7:0] tag_addr = tag_write ? req_index : lookup_index;

    wire data0_way_write = refill_write && !req_replace_way;
    wire data1_way_write = refill_write &&  req_replace_way;

    wire [3:0] data0_we0 = (data0_way_write && refill_word == 2'd0) ? 4'hf : 4'h0;
    wire [3:0] data0_we1 = (data0_way_write && refill_word == 2'd1) ? 4'hf : 4'h0;
    wire [3:0] data0_we2 = (data0_way_write && refill_word == 2'd2) ? 4'hf : 4'h0;
    wire [3:0] data0_we3 = (data0_way_write && refill_word == 2'd3) ? 4'hf : 4'h0;
    wire [3:0] data1_we0 = (data1_way_write && refill_word == 2'd0) ? 4'hf : 4'h0;
    wire [3:0] data1_we1 = (data1_way_write && refill_word == 2'd1) ? 4'hf : 4'h0;
    wire [3:0] data1_we2 = (data1_way_write && refill_word == 2'd2) ? 4'hf : 4'h0;
    wire [3:0] data1_we3 = (data1_way_write && refill_word == 2'd3) ? 4'hf : 4'h0;

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

    mycpu_cache_data_bank_sram u_data0_bank0(
        .addra(ram_addr), .clka(clk), .dina(mem_rdata), .douta(data0_word0),
        .ena(1'b1), .wea(data0_we0)
    );
    mycpu_cache_data_bank_sram u_data0_bank1(
        .addra(ram_addr), .clka(clk), .dina(mem_rdata), .douta(data0_word1),
        .ena(1'b1), .wea(data0_we1)
    );
    mycpu_cache_data_bank_sram u_data0_bank2(
        .addra(ram_addr), .clka(clk), .dina(mem_rdata), .douta(data0_word2),
        .ena(1'b1), .wea(data0_we2)
    );
    mycpu_cache_data_bank_sram u_data0_bank3(
        .addra(ram_addr), .clka(clk), .dina(mem_rdata), .douta(data0_word3),
        .ena(1'b1), .wea(data0_we3)
    );
    mycpu_cache_data_bank_sram u_data1_bank0(
        .addra(ram_addr), .clka(clk), .dina(mem_rdata), .douta(data1_word0),
        .ena(1'b1), .wea(data1_we0)
    );
    mycpu_cache_data_bank_sram u_data1_bank1(
        .addra(ram_addr), .clka(clk), .dina(mem_rdata), .douta(data1_word1),
        .ena(1'b1), .wea(data1_we1)
    );
    mycpu_cache_data_bank_sram u_data1_bank2(
        .addra(ram_addr), .clka(clk), .dina(mem_rdata), .douta(data1_word2),
        .ena(1'b1), .wea(data1_we2)
    );
    mycpu_cache_data_bank_sram u_data1_bank3(
        .addra(ram_addr), .clka(clk), .dina(mem_rdata), .douta(data1_word3),
        .ena(1'b1), .wea(data1_we3)
    );

    mycpu_cache_tag_sram u_tag0(
        .addra(tag_addr), .clka(clk), .dina(req_paddr[31:12]), .douta(tag0_dout),
        .ena(1'b1), .wea(tag_write && !req_replace_way)
    );
    mycpu_cache_tag_sram u_tag1(
        .addra(tag_addr), .clka(clk), .dina(req_paddr[31:12]), .douta(tag1_dout),
        .ena(1'b1), .wea(tag_write &&  req_replace_way)
    );

    wire [127:0] data0_line = {data0_word3, data0_word2, data0_word1, data0_word0};
    wire [127:0] data1_line = {data1_word3, data1_word2, data1_word1, data1_word0};

    wire hit0 = valid0[req_index] && tag0_dout == req_paddr[31:12];
    wire hit1 = valid1[req_index] && tag1_dout == req_paddr[31:12];
    wire hit = hit0 || hit1;
    wire hit_way = hit1;
    wire replace_way = valid0[req_index] == 1'b0 ? 1'b0 :
                       valid1[req_index] == 1'b0 ? 1'b1 : ~used[req_index];

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

    always @(posedge clk) begin
        if (!resetn) begin
            state <= S_IDLE;
            req_index <= 8'b0;
            req_paddr <= 32'b0;
            req_word <= 2'b0;
            req_uncached <= 1'b0;
            req_replace_way <= 1'b0;
            req_is_cacop <= 1'b0;
            req_cacop_code <= 2'b0;
            req_cacop_way <= 1'b0;
            refill_word <= 2'b0;
            resp_data <= 32'b0;
            valid0 <= 256'b0;
            valid1 <= 256'b0;
            used <= 256'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (cacop_req) begin
                        req_index <= cacop_index;
                        req_paddr <= cacop_paddr;
                        req_word <= 2'b0;
                        req_uncached <= 1'b0;
                        req_is_cacop <= 1'b1;
                        req_cacop_code <= cacop_code;
                        req_cacop_way <= cacop_way;
                        state <= S_LOOKUP;
                    end else if (fetch_req) begin
                        req_index <= fetch_index;
                        req_paddr <= fetch_paddr;
                        req_word <= fetch_paddr[3:2];
                        req_uncached <= fetch_uncached;
                        req_is_cacop <= 1'b0;
                        refill_word <= 2'b0;
                        if (fetch_uncached) begin
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
                                valid0[req_index] <= 1'b0;
                            end
                            if (hit1) begin
                                valid1[req_index] <= 1'b0;
                            end
                        end else begin
                            if (req_cacop_way == 1'b0) begin
                                valid0[req_index] <= 1'b0;
                            end else begin
                                valid1[req_index] <= 1'b0;
                            end
                        end
                        state <= S_CACOP_RESP;
                    end else if (hit) begin
                        resp_data <= select_word(hit_way ? data1_line : data0_line, req_word);
                        used[req_index] <= hit_way;
                        state <= S_HIT_RESP;
                    end else begin
                        req_replace_way <= replace_way;
                        refill_word <= 2'b0;
                        state <= S_REF_REQ;
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
                        if (refill_word == req_word) begin
                            resp_data <= mem_rdata;
                        end
                        if (refill_word == 2'd3) begin
                            if (req_replace_way == 1'b0) begin
                                valid0[req_index] <= 1'b1;
                            end else begin
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
