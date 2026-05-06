/*------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Copyright (c) 2016, Loongson Technology Corporation Limited.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this 
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, 
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of Loongson Technology Corporation Limited nor the names of 
its contributors may be used to endorse or promote products derived from this 
software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL LOONGSON TECHNOLOGY CORPORATION LIMITED BE LIABLE
TO ANY PARTY FOR DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------------
------------------------------------------------------------------------------*/
`timescale 1ns / 1ps
`include "soc_config.vh"

`define CONFREG_NUM_REG         u_soc_top.u_confreg.num_data
`define CONFREG_OPEN_TRACE      1'b0
`define CONFREG_NUM_MONITOR     u_soc_top.u_confreg.num_monitor
`define UART_PSEL               u_soc_top.APB_DEV.uart0.PSEL
`define UART_PENBLE             u_soc_top.APB_DEV.uart0.PENABLE
`define UART_PWRITE             u_soc_top.APB_DEV.uart0.PWRITE
`define UART_WADDR              u_soc_top.APB_DEV.uart0.PADDR[7:0]
`define UART_WDATA              u_soc_top.APB_DEV.uart0.PWDATA[7:0]
`define MIG_AXI                 u_soc_top.ddr3.u_axi_wrap_ddr.mig_axi
`define END_PC 32'h1c000200



module tb_top( );
reg resetn;
reg clk;

//goio
wire [15:0] led;
wire [1 :0] led_rg0;
wire [1 :0] led_rg1;
wire [7 :0] num_csn;
wire [6 :0] num_a_g;
wire [7 :0] switch;
wire [3 :0] btn_key_col;
wire [3 :0] btn_key_row;
wire [1 :0] btn_step;
assign switch      = 8'hff;
assign btn_key_row = 4'd0;
assign btn_step    = 2'd3;

//ddr3
wire  [12:0]  ddr3_addr;
wire  [2 :0]  ddr3_ba;
wire  ddr3_ras_n;
wire  ddr3_cas_n;
wire  ddr3_we_n;
wire  ddr3_odt;
wire  ddr3_reset_n;
wire  ddr3_cke;
wire  [1:0]  ddr3_dm;
wire  ddr3_ck_p;
wire  ddr3_ck_n;
wire  [15:0]  ddr3_dq;
wire  [1:0]  ddr3_dqs_p;
wire  [1:0]  ddr3_dqs_n;

initial
begin
    clk = 1'b0;
    resetn = 1'b0;
    #2000;
    resetn = 1'b1;
end
always #5 clk=~clk;
soc_top #(.SIMULATION(1'b1)) u_soc_top
(
       .resetn_fpga              ( resetn         ), 
       .clk                      ( clk            ),

        //------gpio------- 
        .num_csn                 ( num_csn        ),
        .num_a_g                 ( num_a_g        ),
        .led                     ( led            ),
        .led_rg0                 ( led_rg0        ),
        .led_rg1                 ( led_rg1        ),
        .switch_fpga             ( switch         ),
        .btn_key_col             ( btn_key_col    ),
        .btn_key_row             ( btn_key_row    ),
        .btn_step_fpga           ( btn_step       ),

        //------ddr3-------
        .ddr3_addr               ( ddr3_addr      ),
        .ddr3_ba                 ( ddr3_ba        ),
        .ddr3_ras_n              ( ddr3_ras_n     ),
        .ddr3_cas_n              ( ddr3_cas_n     ),
        .ddr3_we_n               ( ddr3_we_n      ),
        .ddr3_odt                ( ddr3_odt       ),
        .ddr3_reset_n            ( ddr3_reset_n   ),
        .ddr3_cke                ( ddr3_cke       ),
        .ddr3_dm                 ( ddr3_dm        ),
        .ddr3_ck_p               ( ddr3_ck_p      ),
        .ddr3_ck_n               ( ddr3_ck_n      ),
        .ddr3_dq                 ( ddr3_dq        ),
        .ddr3_dqs_p              ( ddr3_dqs_p     ),
        .ddr3_dqs_n              ( ddr3_dqs_n     )
    );   

//"cpu_clk" means cpu core clk
//"sys_clk" means system clk
//"wb" means write-back stage in pipeline
//"rf" means regfiles in cpu
//"w" in "wen/wnum/wdata" means writing
wire cpu_clk;
wire sys_clk;
wire [31:0] debug_wb_pc;
wire [3 :0] debug_wb_rf_wen;
wire [4 :0] debug_wb_rf_wnum;
wire [31:0] debug_wb_rf_wdata;
assign cpu_clk           = u_soc_top.cpu_clk;
assign sys_clk           = u_soc_top.sys_clk;
assign debug_wb_pc       = u_soc_top.debug_wb_pc;
assign debug_wb_rf_wen   = u_soc_top.debug_wb_rf_wen;
assign debug_wb_rf_wnum  = u_soc_top.debug_wb_rf_wnum;
assign debug_wb_rf_wdata = u_soc_top.debug_wb_rf_wdata;

//monitor numeric display
reg [7:0] err_count;
wire [31:0] confreg_num_reg = `CONFREG_NUM_REG;
reg  [31:0] confreg_num_reg_r;
always @(posedge sys_clk)
begin
    confreg_num_reg_r <= confreg_num_reg;
    if (!resetn)
    begin
        err_count <= 8'd0;
    end
    else if (confreg_num_reg_r != confreg_num_reg && `CONFREG_NUM_MONITOR)
    begin
        if(confreg_num_reg[7:0]!=confreg_num_reg_r[7:0]+1'b1)
        begin
            $display("--------------------------------------------------------------");
            $display("[%t] Error(%d)!!! Occurred in number 8'd%02d Functional Test Point!",$time, err_count, confreg_num_reg[31:24]);
            $display("--------------------------------------------------------------");
            err_count <= err_count + 1'b1;
        end
        else if(confreg_num_reg[31:24]!=confreg_num_reg_r[31:24]+1'b1)
        begin
            $display("--------------------------------------------------------------");
            $display("[%t] Error(%d)!!! Unknown, Functional Test Point numbers are unequal!",$time,err_count);
            $display("--------------------------------------------------------------");
            $display("==============================================================");
            err_count <= err_count + 1'b1;
        end
        else
        begin
            $display("----[%t] Number 8'd%02d Functional Test Point PASS!!!", $time, confreg_num_reg[31:24]);
        end
    end
end

//monitor test
initial
begin
    $timeformat(-9,0," ns",10);
    while(!resetn) #5;
    $display("==============================================================");
    $display("Test begin!");

    #10000;
    while(`CONFREG_NUM_MONITOR)
    begin
        #10000;
        $display ("        [%t] Test is running, debug_wb_pc = 0x%8h",$time, debug_wb_pc);
    end
end

//妯℃嫙涓插彛鎵撳嵃
wire uart_display;
wire [7:0] uart_data;
wire uart_wen;
assign uart_wen = (`UART_PSEL == 1'b1) &&  (`UART_PENBLE == 1'b1) && (`UART_PWRITE == 1'b1);
assign uart_display = (uart_wen == 1'b1) && (`UART_WADDR == 8'he0);
assign uart_data    = `UART_WDATA;

always @(posedge u_soc_top.sys_clk)
begin
    if(uart_display)
    begin
        if(uart_data==8'hff)
        begin
            ;//$finish;
        end
        else
        begin
            $write("%c",uart_data);
        end
    end
end

//test end
reg  debug_end;
wire global_err = err_count!=8'd0;
wire test_end = (debug_wb_pc==`END_PC) || (uart_display && uart_data==8'hff);
always @(posedge cpu_clk)
begin
    if (!resetn)
    begin
        debug_end <= 1'b0;
    end
    else if(test_end && !debug_end)
    begin
        debug_end <= 1'b1;
        $display("==============================================================");
        $display("Test end!");
        #40;
        // $fclose(trace_ref);
        if (global_err)
        begin
            $display("Fail!!!Total %d errors!",err_count);
        end
        else
        begin
            $display("----PASS!!!");
        end
	    $finish;
	end
end

generate if(`SIMU_USE_DDR==0) begin: sim_ram_tb

    integer software_bin;
    integer err,str;
    reg [31:0] instr;
    integer i;
    initial begin
        software_bin = $fopen("D:/chiplab/software/examples/nscscc_func/obj/main.bin","rb");
        // software_bin = $fopen("../../../../../inst_data.bin","rb");
        err = $ferror(software_bin, str);
        if(!err) begin
            for(i=0;i<262144;i=i+1) begin
                if ($fread(instr,software_bin))begin
                    u_soc_top.sim_ram.u_axi_ram.u_fpga_sram.BRAM[i] <= {instr[7:0],instr[15:8],instr[23:16],instr[31:24]};
                end
                else begin
                    u_soc_top.sim_ram.u_axi_ram.u_fpga_sram.BRAM[i] <= 32'b0;
                end
            end
        end
        $fclose(software_bin);
    end

end
else begin: ddr3_tb

    // AXI4鍐欐暟鎹换鍔?
    task axi4_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            // 鍐欏湴鍧?閫氶亾
            @(posedge `MIG_AXI.ui_clk);
            force `MIG_AXI.s_axi_awid = 4'b0001;
            force `MIG_AXI.s_axi_awaddr = addr[26:0];
            force `MIG_AXI.s_axi_awlen   = 8'h00;
            force `MIG_AXI.s_axi_awsize  = 3'b010;
            force `MIG_AXI.s_axi_awburst = 2'b01;
            force `MIG_AXI.s_axi_awlock  = 1'b0;
            force `MIG_AXI.s_axi_awcache = 4'b0000;
            force `MIG_AXI.s_axi_awprot  = 3'b000;
            force `MIG_AXI.s_axi_awqos   = 4'b0000;
            force `MIG_AXI.s_axi_awvalid = 1'b1;
            
            // 绛夊緟鎻℃墜瀹屾垚
            wait(`MIG_AXI.s_axi_awready);
            @(posedge `MIG_AXI.ui_clk);
            force `MIG_AXI.s_axi_awvalid = 1'b0;
            
            // 鍐欐暟鎹?氶亾
            force `MIG_AXI.s_axi_wdata  = data;
            force `MIG_AXI.s_axi_wstrb  = 4'b1111;
            force `MIG_AXI.s_axi_wlast  = 1'b1;
            force `MIG_AXI.s_axi_wvalid = 1'b1;
            
            // 绛夊緟鍐欐暟鎹彙鎵嬪畬鎴?
            wait(`MIG_AXI.s_axi_wready);
            @(posedge `MIG_AXI.ui_clk);
            force `MIG_AXI.s_axi_wvalid = 1'b0;
            
            // 绛夊緟鍐欏搷搴?
            force `MIG_AXI.s_axi_bready = 1'b1;
            wait(`MIG_AXI.s_axi_bvalid);
            @(posedge `MIG_AXI.ui_clk);
            force `MIG_AXI.s_axi_bready = 1'b0;
        end
    endtask

    // 浠庢枃浠跺啓鍏XI鎬荤嚎鐨勪换鍔?
    task write_file;
        input [31:0] base_addr;  // 鍩哄湴鍧?
        input string filename;    // 鏂囦欢鍚?
        reg [31:0] data;         // 涓存椂鏁版嵁瀛樺偍
        integer fd;              // 鏂囦欢鎻忚堪绗?
        integer bytes_read;      // 璇诲彇鐨勫瓧鑺傛暟
        integer addr_offset;     // 鍦板潃鍋忕Щ
        begin
            // 鎵撳紑浜岃繘鍒舵枃浠?
            fd = $fopen(filename, "rb");
            if (fd == 0) begin
                $display("Error: Unable to open file %s", filename);
                return;
            end
            
            addr_offset = 0;
            
            // 寰幆璇诲彇鏂囦欢鍐呭骞跺啓鍏XI鎬荤嚎
            while (!$feof(fd)) begin
                bytes_read = $fread(data, fd);
                if (bytes_read > 0) begin
                    // 璋冪敤AXI鍐欎换鍔?
                    axi4_write(
                        base_addr + addr_offset,  // 鐩爣鍦板潃
                        {data[7:0],data[15:8],data[23:16],data[31:24]} // 鍐欏叆鏁版嵁
                    );
                    addr_offset = addr_offset + 4;
                end
            end
            
            // 鍏抽棴鏂囦欢
            $fclose(fd);
            release `MIG_AXI.s_axi_awid;
            release `MIG_AXI.s_axi_awaddr;
            release `MIG_AXI.s_axi_awlen;
            release `MIG_AXI.s_axi_awsize;
            release `MIG_AXI.s_axi_awburst;
            release `MIG_AXI.s_axi_awlock;
            release `MIG_AXI.s_axi_awcache;
            release `MIG_AXI.s_axi_awprot;
            release `MIG_AXI.s_axi_awqos;
            release `MIG_AXI.s_axi_awvalid;
            release `MIG_AXI.s_axi_wdata ;
            release `MIG_AXI.s_axi_wstrb ;
            release `MIG_AXI.s_axi_wlast ;
            release `MIG_AXI.s_axi_wvalid;
            release `MIG_AXI.s_axi_bready;
            $display("File %s is written, and a total of %0d bytes are written", filename, addr_offset);
        end
    endtask

    initial begin
        force u_soc_top.ddr_data_init = 1'b0;
        wait(`MIG_AXI.init_calib_complete);
        write_file(32'h1c000000,"../../../../../inst_data.bin");
        @(posedge `MIG_AXI.ui_clk);
        force u_soc_top.ddr3.u_axi_wrap_ddr.u_Axi_CDC.axiOutRst = 1'b0;
        @(posedge `MIG_AXI.ui_clk);
        force u_soc_top.ddr3.u_axi_wrap_ddr.u_Axi_CDC.axiOutRst = 1'b1;
        force u_soc_top.ddr_data_init = 1'b1;
    end

    ddr3_model	u_ddr3_model (	
        .rst_n   		(resetn),	
        .ck      		(ddr3_ck_p),	
        .ck_n    		(ddr3_ck_n),	
        .cke     		(ddr3_cke),	
        .cs_n    		(1'b0),	
        .ras_n   		(ddr3_ras_n),	
        .cas_n   		(ddr3_cas_n),	
        .we_n    		(ddr3_we_n),	
        .dm_tdqs 		(ddr3_dm),	
        .ba      		(ddr3_ba),	
        .addr    		(ddr3_addr),	
        .dq      		(ddr3_dq),	
        .dqs     		(ddr3_dqs_p),	
        .dqs_n   		(ddr3_dqs_n),	
        .tdqs_n  		(),
        .odt     		(ddr3_odt)	
    );

end
endgenerate

/**************axi鍗忚娴嬭瘯******************/
/*
reg [31:0] read_data [3:0];
initial begin
    wait(u_soc_top.cpu_resetn);
    force u_soc_top.u_cpu.awvalid = 1'b0;
    force u_soc_top.u_cpu.wvalid  = 1'b0;
    force u_soc_top.u_cpu.bready  = 1'b0;
    force u_soc_top.u_cpu.arvalid = 1'b0;
    force u_soc_top.u_cpu.rready  = 1'b0;
    // 鍐欏湴鍧?閫氶亾
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.awid = 4'h1;
    force u_soc_top.u_cpu.awaddr = 32'h1c000000;
    force u_soc_top.u_cpu.awlen   = 8'h00;
    force u_soc_top.u_cpu.awsize  = 3'b010;
    force u_soc_top.u_cpu.awburst = 2'b01;
    force u_soc_top.u_cpu.awlock  = 1'b0;
    force u_soc_top.u_cpu.awcache = 4'b0000;
    force u_soc_top.u_cpu.awprot  = 3'b000;
    force u_soc_top.u_cpu.awvalid = 1'b1;

    // 绛夊緟鎻℃墜瀹屾垚
    #1;
    wait(u_soc_top.u_cpu.awready);
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.awid = 4'h2;
    force u_soc_top.u_cpu.awaddr = 32'h1c000004;
    force u_soc_top.u_cpu.awlen   = 8'h00;
    force u_soc_top.u_cpu.awsize  = 3'b010;
    force u_soc_top.u_cpu.awburst = 2'b01;
    force u_soc_top.u_cpu.awlock  = 1'b0;
    force u_soc_top.u_cpu.awcache = 4'b0000;
    force u_soc_top.u_cpu.awprot  = 3'b000;
    force u_soc_top.u_cpu.awvalid = 1'b1;

    // 绛夊緟鎻℃墜瀹屾垚
    #1;
    wait(u_soc_top.u_cpu.awready);
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.awid = 4'h3;
    force u_soc_top.u_cpu.awaddr = 32'h1c000008;
    force u_soc_top.u_cpu.awlen   = 8'h00;
    force u_soc_top.u_cpu.awsize  = 3'b010;
    force u_soc_top.u_cpu.awburst = 2'b01;
    force u_soc_top.u_cpu.awlock  = 1'b0;
    force u_soc_top.u_cpu.awcache = 4'b0000;
    force u_soc_top.u_cpu.awprot  = 3'b000;
    force u_soc_top.u_cpu.awvalid = 1'b1;

    // 绛夊緟鎻℃墜瀹屾垚
    #1;
    wait(u_soc_top.u_cpu.awready);
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.awid = 4'h4;
    force u_soc_top.u_cpu.awaddr = 32'h1c00000c;
    force u_soc_top.u_cpu.awlen   = 8'h00;
    force u_soc_top.u_cpu.awsize  = 3'b010;
    force u_soc_top.u_cpu.awburst = 2'b01;
    force u_soc_top.u_cpu.awlock  = 1'b0;
    force u_soc_top.u_cpu.awcache = 4'b0000;
    force u_soc_top.u_cpu.awprot  = 3'b000;
    force u_soc_top.u_cpu.awvalid = 1'b1;

    // 绛夊緟鎻℃墜瀹屾垚
    #1;
    wait(u_soc_top.u_cpu.awready);
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.awvalid = 1'b0;

    // 鍐欐暟鎹?氶亾
    force u_soc_top.u_cpu.wid    = 4'h1;
    force u_soc_top.u_cpu.wdata  = 32'h1111_1111;
    force u_soc_top.u_cpu.wstrb  = 4'b1111;
    force u_soc_top.u_cpu.wlast  = 1'b1;
    force u_soc_top.u_cpu.wvalid = 1'b1;

    // 绛夊緟鍐欐暟鎹彙鎵嬪畬鎴?
    #1;
    wait(u_soc_top.u_cpu.wready);
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.wid    = 4'h4;
    force u_soc_top.u_cpu.wdata  = 32'h4444_4444;
    force u_soc_top.u_cpu.wstrb  = 4'b1111;
    force u_soc_top.u_cpu.wlast  = 1'b1;
    force u_soc_top.u_cpu.wvalid = 1'b1;

    // 绛夊緟鍐欐暟鎹彙鎵嬪畬鎴?
    #1;
    wait(u_soc_top.u_cpu.wready);
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.wid    = 4'h3;
    force u_soc_top.u_cpu.wdata  = 32'h3333_3333;
    force u_soc_top.u_cpu.wstrb  = 4'b1111;
    force u_soc_top.u_cpu.wlast  = 1'b1;
    force u_soc_top.u_cpu.wvalid = 1'b1;

    // 绛夊緟鍐欐暟鎹彙鎵嬪畬鎴?
    #1;
    wait(u_soc_top.u_cpu.wready);
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.wid    = 4'h2;
    force u_soc_top.u_cpu.wdata  = 32'h2222_2222;
    force u_soc_top.u_cpu.wstrb  = 4'b1111;
    force u_soc_top.u_cpu.wlast  = 1'b1;
    force u_soc_top.u_cpu.wvalid = 1'b1;

    // 绛夊緟鍐欐暟鎹彙鎵嬪畬鎴?
    #1;
    wait(u_soc_top.u_cpu.wready);
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.wvalid = 1'b0;

    // 绛夊緟鍐欏搷搴?
    force u_soc_top.u_cpu.bready = 1'b1;
    wait(u_soc_top.u_cpu.bvalid);
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.bready = 1'b0;
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.bready = 1'b1;
    wait(u_soc_top.u_cpu.bvalid);
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.bready = 1'b0;
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.bready = 1'b1;
    wait(u_soc_top.u_cpu.bvalid);
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.bready = 1'b0;
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.bready = 1'b1;
    wait(u_soc_top.u_cpu.bvalid);
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.bready = 1'b0;

    // 璇诲湴鍧?閫氶亾
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.arid    = 4'h1;
    force u_soc_top.u_cpu.araddr  = 32'h1c000000;
    force u_soc_top.u_cpu.arlen   = 8'h00;
    force u_soc_top.u_cpu.arsize  = 3'b010;
    force u_soc_top.u_cpu.arburst = 2'b01;
    force u_soc_top.u_cpu.arlock  = 1'b0;
    force u_soc_top.u_cpu.arcache = 4'b0000;
    force u_soc_top.u_cpu.arprot  = 3'b000;
    force u_soc_top.u_cpu.arvalid = 1'b1;
    
    // 绛夊緟璇诲湴鍧?鎻℃墜瀹屾垚
    #1;
    wait(u_soc_top.u_cpu.arready);
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.arid    = 4'h2;
    force u_soc_top.u_cpu.araddr  = 32'h1c000004;
    force u_soc_top.u_cpu.arlen   = 8'h00;
    force u_soc_top.u_cpu.arsize  = 3'b010;
    force u_soc_top.u_cpu.arburst = 2'b01;
    force u_soc_top.u_cpu.arlock  = 1'b0;
    force u_soc_top.u_cpu.arcache = 4'b0000;
    force u_soc_top.u_cpu.arprot  = 3'b000;
    force u_soc_top.u_cpu.arvalid = 1'b1;

    // 绛夊緟璇诲湴鍧?鎻℃墜瀹屾垚
    #1;
    wait(u_soc_top.u_cpu.arready);
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.arid    = 4'h3;
    force u_soc_top.u_cpu.araddr  = 32'h1c000008;
    force u_soc_top.u_cpu.arlen   = 8'h00;
    force u_soc_top.u_cpu.arsize  = 3'b010;
    force u_soc_top.u_cpu.arburst = 2'b01;
    force u_soc_top.u_cpu.arlock  = 1'b0;
    force u_soc_top.u_cpu.arcache = 4'b0000;
    force u_soc_top.u_cpu.arprot  = 3'b000;
    force u_soc_top.u_cpu.arvalid = 1'b1;

    // 绛夊緟璇诲湴鍧?鎻℃墜瀹屾垚
    #1;
    wait(u_soc_top.u_cpu.arready);
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.arid    = 4'h4;
    force u_soc_top.u_cpu.araddr  = 32'h1c00000c;
    force u_soc_top.u_cpu.arlen   = 8'h00;
    force u_soc_top.u_cpu.arsize  = 3'b010;
    force u_soc_top.u_cpu.arburst = 2'b01;
    force u_soc_top.u_cpu.arlock  = 1'b0;
    force u_soc_top.u_cpu.arcache = 4'b0000;
    force u_soc_top.u_cpu.arprot  = 3'b000;
    force u_soc_top.u_cpu.arvalid = 1'b1;

    // 绛夊緟璇诲湴鍧?鎻℃墜瀹屾垚
    #1;
    wait(u_soc_top.u_cpu.arready);
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.arvalid = 1'b0;
    
    // 璇绘暟鎹?氶亾
    force u_soc_top.u_cpu.rready = 1'b1;
    
    // 绛夊緟璇绘暟鎹湁鏁?
    #1;
    wait(u_soc_top.u_cpu.rvalid);
    read_data[0] = u_soc_top.u_cpu.rdata;
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.rready = 1'b0;
    @(posedge u_soc_top.u_cpu.aclk);

    force u_soc_top.u_cpu.rready = 1'b1;
    #1;
    wait(u_soc_top.u_cpu.rvalid);
    read_data[1] = u_soc_top.u_cpu.rdata;
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.rready = 1'b0;
    @(posedge u_soc_top.u_cpu.aclk);

    force u_soc_top.u_cpu.rready = 1'b1;
    #1;
    wait(u_soc_top.u_cpu.rvalid);
    read_data[2] = u_soc_top.u_cpu.rdata;
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.rready = 1'b0;
    @(posedge u_soc_top.u_cpu.aclk);

    force u_soc_top.u_cpu.rready = 1'b1;
    #1;
    wait(u_soc_top.u_cpu.rvalid);
    read_data[3] = u_soc_top.u_cpu.rdata;
    @(posedge u_soc_top.u_cpu.aclk);
    force u_soc_top.u_cpu.rready = 1'b0;
    @(posedge u_soc_top.u_cpu.aclk);

    $finish;
end
*/
endmodule
