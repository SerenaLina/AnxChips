`include "mycpu.h"

module mem_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          ws_allowin    ,
    output                         ms_allowin    ,
    output                         ms_load_wait   ,
    //from es
    input                          es_to_ms_valid,
    input  [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus  ,
    //to ws
    output                         ms_to_ws_valid,
    output [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus  ,
    output [31:0]                  ms_result,
    
    //from data-sram
    input  [31                 :0] data_sram_rdata,
    output [4:0] ms_to_ds_dest
);

reg         ms_valid;
wire        ms_ready_go;

reg [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus_r;
wire        ms_res_from_mem;
wire        ms_gr_we;
wire [ 4:0] ms_dest;
wire [31:0] ms_alu_result;
wire [31:0] ms_pc;
wire        ms_load_wait;
wire  [31:0]      ms_alusrc1;
wire  [31:0]      ms_alusrc2;
wire         ms_src2_is_imm;
wire         ms_div_complete;

wire [31:0] mem_result;
wire [31:0] ms_final_result;
wire  [31:0] ms_inst;
wire  [63:0] ms_div_result;
wire  [4:0]  ms_load_op;
wire  [31:0] data_sram_addr;

wire  is_ldw = ms_load_op[0];
wire  is_ldb = ms_load_op[1];
wire  is_ldh = ms_load_op[2];
wire  is_ldbu = ms_load_op[3];
wire  is_ldhu = ms_load_op[4];
wire  [31:0] ld_result;
wire  [31:0] ld_mask;



wire [2:0] ms_store_op;
assign {ms_res_from_mem,  //70:70
        ms_gr_we       ,  //69:69
        ms_dest        ,  //68:64
        ms_alu_result  ,  //63:32
        ms_pc          ,  //31:0
        ms_inst        ,  // 32
        ms_alusrc1     ,  // 32
        ms_alusrc2      , // 32
        ms_src2_is_imm  ,// 1
        ms_div_result   , // 64
        ms_div_complete ,   // 1
        ms_load_op       ,  // 5
        ms_store_op     ,  // 3
        data_sram_addr   // 32
       } = es_to_ms_bus_r;

assign ms_to_ws_bus = {ms_gr_we       ,  //69:69
                       ms_dest        ,  //68:64
                       ms_final_result,  //63:32
                       ms_pc          ,   //31:0
                        ms_inst        ,
                        ms_alusrc1     ,  // 32
                        ms_alusrc2      , // 32
                        ms_src2_is_imm  ,// 1
                        ms_div_result    ,// 64
                        ms_div_complete    // 1
                      };

assign ms_ready_go    = 1'b1;
assign ms_allowin     = !ms_valid || ms_ready_go && ws_allowin;
assign ms_to_ws_valid = ms_valid && ms_ready_go;
assign ms_load_wait = ms_res_from_mem; // wait for load result
always @(posedge clk) begin
    if (reset) begin
        ms_valid <= 1'b0;
    end
    else if (ms_allowin) begin
        ms_valid <= es_to_ms_valid;
    end

    if (es_to_ms_valid && ms_allowin) begin
        es_to_ms_bus_r  <= es_to_ms_bus;
    end
end

assign mem_result   = data_sram_rdata;
assign ld_mask     = (is_ldb || is_ldbu) ? 32'h000000ff :
                   (is_ldh || is_ldhu) ? 32'h0000ffff :
                   32'hffffffff;
assign ld_result   = (data_sram_addr[1:0] == 2'b00) ? (mem_result & ld_mask) :
                      (data_sram_addr[1:0] == 2'b01) ? ((mem_result >> 8) & ld_mask) :
                      (data_sram_addr[1:0] == 2'b10) ? ((mem_result >> 16) & ld_mask) :
                                                       ((mem_result >> 24) & ld_mask);

assign ms_final_result = is_ldw ? mem_result :
                         is_ldb ? {{24{ld_result[7]}}, ld_result[7:0]} :
                         is_ldh ? {{16{ld_result[15]}}, ld_result[15:0]} :
                         is_ldbu ? {24'b0, ld_result[7:0]} :
                         is_ldhu ? {16'b0, ld_result[15:0]} :
                         ms_alu_result;

assign ms_to_ds_dest = (ms_valid && ms_gr_we) ? ms_dest : 5'b0; // only forward valid dest to ID stage for data hazard detection
assign ms_result = ms_res_from_mem ? ms_final_result : ms_alu_result;

endmodule
