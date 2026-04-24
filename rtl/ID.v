`include "mycpu.h"

module id_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          es_allowin    ,
    output                         ds_allowin    ,
    //from fs
    input                          fs_to_ds_valid,
    input  [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus  ,
    input                          es_res_from_mem   ,
    input [4:0] es_to_ds_dest,
    input [4:0] ms_to_ds_dest,
    input [4:0] ws_to_ds_dest,
    input [31:0] es_result,
    input [31:0] ms_result,
    input [31:0] ws_result,
    input        es_valid,
    input        ms_valid,
    input        ws_valid,
    //to es
    output                         ds_to_es_valid,
    output [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus  ,
    //to fs
    output [`BR_BUS_WD       -1:0] br_bus        ,
    //to rf: for write back
    input  [`WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus,
    output [4:0] debug_id_rf_raddr1,
    output [31:0] debug_id_rf_rdata1
);

wire        br_taken;
wire [31:0] br_target;
wire        br_cancel;

wire [31:0] ds_pc;
wire [31:0] ds_inst;

reg         ds_valid   ;
wire        ds_ready_go;

wire [27:0] alu_op;
wire [4:0]  load_op;
wire [2:0]  store_op;

wire        src1_is_pc;
wire        src2_is_imm;
wire        res_from_mem;
wire        dst_is_r1;
wire        gr_we;
wire        mem_we;
wire        src_reg_is_rd;
wire [4: 0] dest;
wire [31:0] rj_value;
wire [31:0] rkd_value;
wire [31:0] imm;
wire [31:0] br_offs;
wire [31:0] jirl_offs;

wire [ 5:0] op_31_26;
wire [ 3:0] op_25_22;
wire [ 1:0] op_21_20;
wire [ 4:0] op_19_15;
wire [ 4:0] rd;
wire [ 4:0] rj;
wire [ 4:0] rk;
wire [11:0] i12;
wire [19:0] i20;
wire [15:0] i16;
wire [25:0] i26;

wire [63:0] op_31_26_d;
wire [15:0] op_25_22_d;
wire [ 3:0] op_21_20_d;
wire [31:0] op_19_15_d;

wire [`INST_BUS_WD-1:0] inst_bus;

wire        need_ui5;
wire        need_si12;
wire        need_si16;
wire        need_si20;
wire        need_si26;
wire        need_ui12;
wire        src2_is_4;

wire [ 4:0] rf_raddr1;
wire [31:0] rf_rdata1;
wire [ 4:0] rf_raddr2;
wire [31:0] rf_rdata2;

wire        rf_we   ;
wire [ 4:0] rf_waddr;
wire [31:0] rf_wdata;

wire [31:0] alu_src1   ;
wire [31:0] alu_src2   ;
wire [31:0] alu_result ;

wire [31:0] mem_result;
wire [31:0] final_result;


// ============== Instruction Field Extraction
assign op_31_26  = ds_inst[31:26];
assign op_25_22  = ds_inst[25:22];
assign op_21_20  = ds_inst[21:20];
assign op_19_15  = ds_inst[19:15];

assign rd   = ds_inst[ 4: 0];
assign rj   = ds_inst[ 9: 5];
assign rk   = ds_inst[14:10];

assign i12  = ds_inst[21:10];
assign i20  = ds_inst[24: 5];
assign i16  = ds_inst[25:10];
assign i26  = {ds_inst[ 9: 0], ds_inst[25:10]};

// ============== Decoders
decoder_6_64 u_dec0(.in(op_31_26 ), .out(op_31_26_d ));
decoder_4_16 u_dec1(.in(op_25_22 ), .out(op_25_22_d ));
decoder_2_4  u_dec2(.in(op_21_20 ), .out(op_21_20_d ));
decoder_5_32 u_dec3(.in(op_19_15 ), .out(op_19_15_d ));

// ============== inst_decode module instance
inst_decode u_inst_decode(
    .ds_inst    (ds_inst    ),
    .op_31_26_d (op_31_26_d ),
    .op_25_22_d (op_25_22_d ),
    .op_21_20_d (op_21_20_d ),
    .op_19_15_d (op_19_15_d ),
    .inst_bus   (inst_bus   )
);

// ============== op_decode module instance
op_decode u_op_decode(
    .inst_bus       (inst_bus       ),
    .alu_op         (alu_op         ),
    .load_op        (load_op        ),
    .store_op       (store_op       )
);

// ============== imm module instance
imm u_imm(
    .inst_bus       (inst_bus       ),
    .rk             (rk             ),
    .i12            (i12            ),
    .i20            (i20            ),
    .i16            (i16            ),
    .i26            (i26            ),
    .imm            (imm            ),
    .need_ui5       (need_ui5       ),
    .need_si12      (need_si12      ),
    .need_si16      (need_si16      ),
    .need_si20      (need_si20      ),
    .need_si26      (need_si26      ),
    .need_ui12      (need_ui12      ),
    .src2_is_4      (src2_is_4      )
);

// ============== controller module instance
controller u_controller(
    .inst_bus       (inst_bus       ),
    .src_reg_is_rd  (src_reg_is_rd  ),
    .src1_is_pc     (src1_is_pc     ),
    .src2_is_imm    (src2_is_imm    ),
    .res_from_mem   (res_from_mem   ),
    .dst_is_r1      (dst_is_r1      ),
    .gr_we          (gr_we          ),
    .mem_we         (mem_we         )
);

assign dest = dst_is_r1 ? 5'd1 : rd;

assign rf_raddr1 = rj;
assign rf_raddr2 = src_reg_is_rd ? rd :rk;
regfile u_regfile(
    .clk    (clk      ),
    .raddr1 (rf_raddr1),
    .rdata1 (rf_rdata1),
    .raddr2 (rf_raddr2),
    .rdata2 (rf_rdata2),
    .we     (rf_we    ),
    .waddr  (rf_waddr ),
    .wdata  (rf_wdata )
    );

// ============== stall and forward signals
wire rj_wait;
wire rk_wait;
wire rd_wait;
wire no_wait;
wire load_wait;

// ============== staller module instance
staller u_staller(
    // 指令译码总线
    .inst_bus        (inst_bus       ),
    
    // 寄存器地址
    .rj              (rj             ),
    .rk              (rk             ),
    .rd              (rd             ),
    
    // 前递目标寄存器
    .es_to_ds_dest   (es_to_ds_dest  ),
    .ms_to_ds_dest   (ms_to_ds_dest  ),
    .ws_to_ds_dest   (ws_to_ds_dest  ),
    
    // 执行阶段信号
    .es_res_from_mem (es_res_from_mem),
    
    // 输出stall信号
    .rj_wait         (rj_wait        ),
    .rk_wait         (rk_wait        ),
    .rd_wait         (rd_wait        ),
    .no_wait         (no_wait        ),
    .load_wait       (load_wait      )
);

// ============== forward module instance
forward u_forward(
    // 寄存器地址
    .rj             (rj             ),
    .rk             (rk             ),
    .rd             (rd             ),
    
    // 前递目标寄存器
    .es_to_ds_dest  (es_to_ds_dest  ),
    .ms_to_ds_dest  (ms_to_ds_dest  ),
    .ws_to_ds_dest  (ws_to_ds_dest  ),
    
    // 前递数据
    .es_result      (es_result      ),
    .ms_result      (ms_result      ),
    .ws_result      (ws_result      ),
    
    // 寄存器文件数据
    .rf_rdata1      (rf_rdata1      ),
    .rf_rdata2      (rf_rdata2      ),
    
    // stall信号
    .rj_wait        (rj_wait        ),
    .rk_wait        (rk_wait        ),
    .rd_wait        (rd_wait        ),
    
    // 输出前递后的数据
    .rj_value       (rj_value       ),
    .rkd_value      (rkd_value      )
);

assign rj_eq_rd = (rj_value == rkd_value);

// ============== branch module instance
branch u_branch(
    .inst_bus       (inst_bus       ),
    .need_si26      (need_si26      ),
    .need_si16      (need_si16      ),
    .i16            (i16            ),
    .i26            (i26            ),
    .rj_value       (rj_value       ),
    .rkd_value      (rkd_value      ),
    .rj_eq_rd       (rj_eq_rd       ),
    .ds_pc          (ds_pc          ),
    .ds_valid       (ds_valid       ),
    .load_wait      (load_wait      ),
    .br_taken       (br_taken       ),
    .br_cancel      (br_cancel      ),
    .br_target      (br_target      ),
    .br_offs        (br_offs        ),
    .jirl_offs      (jirl_offs      )
);

// ===============
assign br_bus = {br_taken,br_target,br_cancel};


reg  [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus_r;

assign {ds_inst,
        ds_pc } = fs_to_ds_bus_r;

assign {rf_we   ,  //37:37
        rf_waddr,  //36:32
        rf_wdata   //31:0
       } = ws_to_rf_bus;

assign ds_to_es_bus = {alu_op       ,   // 28
                       load_op      ,   // 5
                        store_op,       //3
                       src1_is_pc   ,   // 1
                       src2_is_imm  ,   // 1
                       src2_is_4    ,   // 1
                       gr_we        ,   // 1
                       mem_we       ,   // 1
                       dest         ,   // 5
                       imm          ,   // 32
                       rj_value     ,   // 32
                       rkd_value    ,   // 32
                       ds_pc        ,    // 32
                       res_from_mem,
                       ds_inst       // 32
                    };

assign ds_ready_go    = ~load_wait;   // 准备发送
assign ds_allowin     = !ds_valid || ds_ready_go && es_allowin;
assign ds_to_es_valid = ds_valid && ds_ready_go;
always @(posedge clk) begin
    if (reset) begin
        ds_valid <= 1'b0;
    end
    else if (ds_allowin) begin
        ds_valid <= fs_to_ds_valid;
    end
    if (fs_to_ds_valid && (ds_allowin)) begin
        fs_to_ds_bus_r <= fs_to_ds_bus;
    end
end
assign debug_id_rf_raddr1 = rf_raddr1;
assign debug_id_rf_rdata1 = rf_rdata1;

endmodule

