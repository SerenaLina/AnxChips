module axi_bridge (
    input wire aclk,
    input wire aresetn,

    input wire inst_sram_req,
    input wire inst_sram_wr,
    input wire [1:0]inst_sram_size,
    input wire [3:0]inst_sram_wstrb,
    input wire [31:0]inst_sram_addr,
    input wire [31:0]inst_sram_wdata,
    output wire inst_sram_data_ok,
    output wire inst_sram_addr_ok,
    output wire [31:0]inst_sram_rdata,

    // data sram interface（新的）
    input wire data_sram_req,
    input wire data_sram_wr,
    input wire [1:0]data_sram_size,
    input wire [3:0]data_sram_wstrb,
    input wire [31:0]data_sram_addr,
    input wire [31:0]data_sram_wdata,
    output wire data_sram_data_ok,
    output wire data_sram_addr_ok,
    output wire [31:0]data_sram_rdata,

    //  读请求通道
    output reg [3:0] arid,             //  读请求的id号，取指�?0，取数为1
    output wire [31:0] araddr,          //读请求的地址
    output wire [7:0] arlen  ,          //数据传输的拍数，固定�?0
    output reg [2:0] arsize ,          // 请求读的数据的大�?
    output wire [1:0] arburst,          //读请求的类型，固定为0b01
    output wire [1:0] arlock,           //不用管，固定�?0
    output wire [3:0] arcache,          //固定�?0
    output wire [2:0] arprot,           //固定�?0
    output wire arvalid,                //请求地址有效信号
    input wire  arready,                //从方准备好接受地�?传输

    //读响应通道
    input wire [3:0] rid,                //读响应的id号，取指�?0，取数为1
    input wire [31:0] rdata,             //读响应的数据
    input wire rvalid,                   //读请求的数据有效
    output wire rready,                  //cpu准备好接受数据了

    //写请求通道
    output wire [3:0] awid,                //写请求的id号，固定�?1
    output wire [31:0] awaddr,             //写请求的地址
    output wire [7:0] awlen,               //数据传输的拍数，固定�?0
    output wire [2:0] awsize,              //数据传输的大小，字节�?
    output wire [1:0] awburst,             //写请求的类型，固定为0b01
    output wire [1:0] awlock,           //不用管，固定�?0
    output wire [3:0] awcache,          //固定�?0
    output wire [2:0] awprot,           //固定�?0
    output wire awvalid,                //写请求地址有效
    input wire awready,                 //从方准备好接受地�?传输

    //写数据通道
    output wire [3:0] wid,              //写请求的id号，固定为1
    output wire [31:0] wdata,           //写请求的写数据?
    output wire [3:0] wstrb,            //写请求的控制信号
    output wire wlast,                  //固定为1
    output wire wvalid,                 //写请求的数据有效信号
    input wire wready,                  //从方准备好接受数据传输?

    //写响应通道
    input wire bvalid,                  //写响应有效?
    output wire bready                  // cpu准备接受写响应信号?
);
    
    wire rst;
    assign rst = ~aresetn;
    wire clk;
    assign clk = aclk;
    reg [1:0]read_cur_state;
    parameter read_empty = 2'b0;
    parameter read_waiting_valid = 2'b1;
    parameter read_waiting_ready = 2'b10;
    parameter read_waiting_data = 2'b11;
    reg [1:0]read_next_state;

    wire read_req_valid;
    wire read_req_is_data;
    wire [31:0] read_req_addr;
    wire [2:0] read_req_size;

    assign read_req_valid   = (data_sram_req && data_sram_wr == 1'b0) ||
                              (inst_sram_req && inst_sram_wr == 1'b0);
    assign read_req_is_data = (data_sram_req && data_sram_wr == 1'b0);
    assign read_req_addr    = read_req_is_data ? data_sram_addr : inst_sram_addr;
    assign read_req_size    = read_req_is_data ? (data_sram_size == 2'b0  ? 3'd0 :
                                                  data_sram_size == 2'b1  ? 3'd1 :
                                                  data_sram_size == 2'b10 ? 3'd2 : 3'd0) :
                                                  3'd2;

    reg        read_hold_is_data;
    reg [31:0] read_hold_addr;
    reg [2:0]  read_hold_size;

    wire read_use_hold;
    wire read_sel_is_data;
    assign read_use_hold    = (read_cur_state == read_waiting_ready) || (read_cur_state == read_waiting_data);
    assign read_sel_is_data = read_use_hold ? read_hold_is_data : read_req_is_data;

    // Read address channel.  Once ARVALID is asserted, keep ARID/ARADDR/ARSIZE
    // stable until ARREADY accepts the request.
    always @(posedge clk) begin
        if (rst) begin
            read_cur_state <= read_empty;
            read_hold_is_data <= 1'b0;
            read_hold_addr <= 32'b0;
            read_hold_size <= 3'b0;
        end else begin
            read_cur_state <= read_next_state;
            if (read_cur_state == read_empty && read_req_valid) begin
                read_hold_is_data <= read_req_is_data;
                read_hold_addr <= read_req_addr;
                read_hold_size <= read_req_size;
            end
        end
    end

    always @(*) begin
        case (read_cur_state)
            read_empty:
                read_next_state = (read_req_valid && arready) ? read_waiting_data :
                                  read_req_valid              ? read_waiting_ready :
                                                                read_empty;
            read_waiting_ready:
                read_next_state = arready ? read_waiting_data : read_waiting_ready;
            read_waiting_data:
                read_next_state = rvalid ? read_empty : read_waiting_data;
            default:
                read_next_state = read_empty;
        endcase
    end

    always @(*) begin
        arid   = {3'b0, read_sel_is_data};
        arsize = read_use_hold ? read_hold_size : read_req_size;
    end

    assign araddr  = read_use_hold ? read_hold_addr : read_req_addr;
    assign arvalid = (read_cur_state == read_empty && read_req_valid) || (read_cur_state == read_waiting_ready);
    assign arprot  = 3'b0;
    assign arcache = 4'b0;
    assign arlock  = 2'b0;
    assign arburst = 2'b01;
    assign arlen = 8'b0 ;


    //读响应通道
    assign rready = 1'b1;


    //写请求通道
    assign awprot  = 3'b0;
    assign awcache = 4'b0;
    assign awlock  = 2'b0;
    assign awburst = 2'b01;
    assign awlen = 8'b0 ;
    assign awid = 4'b1;
    assign awaddr = data_sram_addr;
    assign awsize = data_sram_size== 2'b0 ?  3'd0 :
                    data_sram_size== 2'b1 ?  3'd1 :
                    data_sram_size== 2'b10 ? 3'd2 : 3'd0;
    assign awvalid = data_sram_req && data_sram_wr == 1'b1 && (write_cur_state == write_empty || write_cur_state == write_waiting_addr);

    //写数据通道
    assign wid = 4'b1;
    assign wdata = data_sram_wdata;
    assign wstrb = data_sram_wstrb;
    assign wlast = 1'b1;
    assign wvalid = data_sram_req && data_sram_wr == 1'b1 && (write_cur_state == write_empty || write_cur_state == write_waiting_data);

    //写响应通道
    assign bready = 1'b1;


    reg [1:0]write_cur_state;
    reg [1:0]write_next_state;
    parameter write_empty = 2'b0;
    parameter write_waiting_data = 2'b01;
    parameter write_waiting_addr = 2'b10;
    parameter write_waiting_success = 2'b11;

    always @(posedge clk)
    begin
        if(rst)
        write_cur_state <= write_empty;
        else
        write_cur_state <= write_next_state;
    end

    always @(*)
    begin
        case (write_cur_state)
            write_empty:
            begin
                if(awvalid && awready && wvalid && wready)
                begin
                    write_next_state = write_waiting_success;
                end
                else if(awvalid&&awready)
                begin
                    write_next_state = write_waiting_data;
                end
                else if(wvalid && wready)
                begin
                    write_next_state = write_waiting_addr;
                end
                else
                begin
                    write_next_state = write_empty;
                end
            end 
            write_waiting_addr:
            begin
                if(awvalid&&awready)
                begin
                    write_next_state = write_waiting_success;
                end
                else
                begin
                    write_next_state = write_waiting_addr;
                end
            end 
            write_waiting_data:
            begin
                if(wvalid && wready)
                begin
                    write_next_state = write_waiting_success;
                end
                else
                begin
                    write_next_state = write_waiting_data;
                end
            end
            write_waiting_success:
            begin
                if(bvalid)
                begin
                    write_next_state  = write_empty;
                end
                else
                begin
                    write_next_state = write_waiting_success;
                end
            end
        endcase
    end

    /* AXI debug removed */
    // Buffer AXI read response to filter spurious rvalid beats
    reg         r_buf_rvalid;
    reg [3:0]   r_buf_rid;
    reg [31:0]  r_buf_rdata;
    always @(posedge aclk) begin
        if(!aresetn) r_buf_rvalid <= 0;
        else r_buf_rvalid <= rvalid;
    end
    always @(posedge aclk) begin
        if(!aresetn) r_buf_rid <= 0;
        else r_buf_rid <= rid;
    end
    always @(posedge aclk) begin
        if(!aresetn) r_buf_rdata <= 0;
        else r_buf_rdata <= rdata;
    end

    //inst_sram — use buffered response
    assign inst_sram_addr_ok = arvalid && arready && arid==4'b0 && read_sel_is_data == 1'b0;
    assign inst_sram_data_ok = r_buf_rvalid && r_buf_rid == 4'b0;
    assign inst_sram_rdata = r_buf_rid == 4'b0 ? r_buf_rdata : 32'b0;

    //data_sram — use buffered response
    assign data_sram_addr_ok = (data_sram_wr == 1'b0 && arvalid && arready && arid==4'b1 && read_sel_is_data == 1'b1)
                           ||(data_sram_wr== 1'b1 && write_next_state==write_waiting_success);
    assign data_sram_data_ok = (r_buf_rvalid && r_buf_rid == 4'b1) || (bvalid&&bready && write_cur_state == write_waiting_success);
    assign data_sram_rdata  =  r_buf_rid == 4'b1 ? r_buf_rdata : 32'b0;

endmodule