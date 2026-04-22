`include "mycpu.h"

module exe_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          ms_allowin    ,
    output                         es_allowin    ,
    //from ds
    input                          ds_to_es_valid,
    input  [`DS_TO_ES_BUS_WD -1:0]  ds_to_es_bus  ,
    input                          ms_load_wait   ,
    //to ms
    output                         es_to_ms_valid,
    output [`ES_TO_MS_BUS_WD -1:0]  es_to_ms_bus  ,
    output [4:0]                   es_to_ds_dest,
    output [31:0]                  es_result,
    output                         es_res_from_mem,



    // data sram interface(write)
    output        data_sram_en   ,
    output [ 3:0] data_sram_we   ,
    output [31:0] data_sram_addr ,
    output [31:0] data_sram_wdata,
    output        debug_es_div_complete
);

reg         es_valid      ;
wire        es_ready_go   ;

reg  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus_r;

wire [27:0] alu_op      ;
wire        es_load_op;
wire        src1_is_pc;
wire        src2_is_imm;
wire        src2_is_4;
wire        res_from_mem;
wire        dst_is_r1;
wire        gr_we;
wire        es_mem_we;
wire [4: 0] dest;
wire [31:0] rj_value;
wire [31:0] rkd_value;
wire [31:0] imm;
wire [31:0] es_pc;
wire [31:0] es_inst;
wire [63:0] div_result;



assign {alu_op,
        es_load_op,
        src1_is_pc,
        src2_is_imm,
        src2_is_4,
        gr_we,
        es_mem_we,
        dest,
        imm,
        rj_value,
        rkd_value,
        es_pc,
        res_from_mem,
        es_inst
       } = ds_to_es_bus_r;

wire [31:0] alu_src1   ;
wire [31:0] alu_src2   ;
wire [31:0] alu_result ;
wire        ready_s;
wire        ready_u;


// did't use in lab7
wire        es_res_from_mem;
assign es_res_from_mem = es_valid ? (es_load_op || ms_load_wait) : 1'b0; // only forward valid load_op to ID stage for data hazard detection



assign es_to_ms_bus = {res_from_mem,  //70:70 1
                       gr_we       ,  //69:69 1
                       dest        ,  //68:64 5
                       alu_result  ,  //63:32 32
                       es_pc,           //31:0
                       es_inst     ,
                       alu_src1    ,  // 32
                       alu_src2    ,  // 32
                       src2_is_imm  ,// 1
                       div_result   , // 64
                       div_complete    // 1
                      };

assign es_ready_go    = (es_valid && (alu_op[24] || alu_op[25] || alu_op[26] || alu_op[27])) ? div_complete : 1'b1; 
assign es_allowin     = !es_valid || (es_ready_go && ms_allowin); 
assign es_to_ms_valid =  es_valid && es_ready_go;
reg div_complete;
always @(posedge clk) begin
    if (reset) begin
        div_complete <= 1'b0;
    end 
    else if (es_allowin && (alu_op[24] || alu_op[25] || alu_op[26] || alu_op[27])) begin
        div_complete <= 1'b0; 
    end
    else if ((alu_op[24] || alu_op[25]) && ready_s) begin
        div_complete <= 1'b1;
    end
    else if ((alu_op[26] || alu_op[27]) && ready_u) begin
        div_complete <= 1'b1;
    end
end
always @(posedge clk) begin
    if (reset) begin
        es_valid <= 1'b0;
    end
    else if (es_allowin) begin
        es_valid <= ds_to_es_valid;
    end

    if ((ds_to_es_valid && es_allowin)) begin
        ds_to_es_bus_r <= ds_to_es_bus;
    end
end

assign alu_src1 = src1_is_pc  ? es_pc  : rj_value;
assign alu_src2 = src2_is_imm ? imm : rkd_value;

alu u_alu(
    .alu_op     (alu_op    ),
    .alu_src1   (alu_src1  ),
    .alu_src2   (alu_src2  ),
    .alu_result (alu_result),
    .reset      (reset),
    .ready_s(ready_s),
    .ready_u(ready_u),
    .clk(clk)
    );

assign data_sram_en    = 1'b1;
assign data_sram_we    = es_mem_we && es_valid ? 4'hf : 4'h0;
assign data_sram_addr  = alu_result;
assign data_sram_wdata = rkd_value;


assign es_to_ds_dest = (es_valid && gr_we) ? dest : 5'b0; // only forward valid dest to ID stage for data hazard detection
assign es_result     = alu_result;
assign debug_es_div_complete = div_complete;
assign div_result = 64'b0;


endmodule
