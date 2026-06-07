module core_top(
    input  wire        aclk,
    input  wire        aresetn,  // low active


    // AXI Read Address Channel
    output wire [3:0]  arid,
    output wire [31:0] araddr,
    output wire [7:0]  arlen,
    output wire [2:0]  arsize,
    output wire [1:0]  arburst,
    output wire [1:0]  arlock,
    output wire [3:0]  arcache,
    output wire [2:0]  arprot,
    output wire        arvalid,
    input  wire        arready,

    input wire [7:0] intrpt,

    // AXI Read Data Channel
    input  wire [3:0]  rid,
    input  wire [31:0] rdata,
    input  wire [1:0]  rresp,
    input  wire        rlast,
    input  wire        rvalid,
    output wire        rready,

    // AXI Write Address Channel
    output wire [3:0]  awid,
    output wire [31:0] awaddr,
    output wire [7:0]  awlen,
    output wire [2:0]  awsize,
    output wire [1:0]  awburst,
    output wire [1:0]  awlock,
    output wire [3:0]  awcache,
    output wire [2:0]  awprot,
    output wire        awvalid,
    input  wire        awready,

    // AXI Write Data Channel
    output wire [3:0]  wid,
    output wire [31:0] wdata,
    output wire [3:0]  wstrb,
    output wire        wlast,
    output wire        wvalid,
    input  wire        wready,

    // AXI Write Response Channel
    input  wire [3:0]  bid,
    input  wire [1:0]  bresp,
    input  wire        bvalid,
    output wire        bready,
    //debug
    input           break_point,//无需实现功能，仅提供接口即可，输入1’b0
    input           infor_flag,//无需实现功能，仅提供接口即可，输入1’b0
    input  [ 4:0]   reg_num,//无需实现功能，仅提供接口即可，输入5’b0
    output          ws_valid,//无需实现功能，仅提供接口即可
    output [31:0]   rf_rdata,//无需实现功能，仅提供接口即可
    // trace debug interface
    output wire [31:0] debug0_wb_pc,
    output wire [ 3:0] debug0_wb_rf_wen,
    output wire [ 4:0] debug0_wb_rf_wnum,
    output wire [31:0] debug0_wb_rf_wdata,
    // pipeline stall debug interface
    output wire        debug_id_allow_in,
    output wire        debug_id_ready_go,
    output wire        debug_exe1_allow_in,
    output wire        debug_exe2_allow_in,
    output wire        debug_mem_allow_in,
    output wire        debug_if_ready_go,
    output wire        debug_pipe_stalled,
    output wire        debug_wb_ex,
    output wire [31:0] debug_id_pc,
    output wire [31:0] debug_id_inst,
    output wire [4:0]  debug_id_rj,
    output wire [4:0]  debug_id_rk,
    output wire [4:0]  debug_id_rd,
    output wire        debug_id_src1_from_ref,
    output wire        debug_id_src2_from_ref,
    output wire [4:0]  debug_exe2_rd,
    output wire        debug_exe2_ref_we,
    output wire [4:0]  debug_mem_rd,
    output wire        debug_mem_ref_we,
    output wire [4:0]  debug_wb_rd,
    output wire        debug_wb_rf_we_dbg
);
    wire        inst_sram_req;
    wire        inst_sram_wr;
    wire [1:0]  inst_sram_size;
    wire [3:0]  inst_sram_wstrb;
    wire [31:0] inst_sram_addr;
    wire [31:0] inst_sram_wdata;
    wire        inst_sram_data_ok;
    wire        real_inst_data_ok;
    assign real_inst_data_ok = inst_sram_data_ok && !inst_req_valid;
    wire        inst_sram_addr_ok;
    wire [31:0] inst_sram_rdata;
    wire        data_sram_req;
    wire        data_sram_wr;
    wire [1:0]  data_sram_size;
    wire [3:0]  data_sram_wstrb;
    wire [31:0] data_sram_addr;
    wire [31:0] data_sram_wdata;
    wire        data_sram_data_ok;
    wire        data_sram_addr_ok;
    wire [31:0] data_sram_rdata;
    wire clk;

    assign clk = aclk;


    assign inst_sram_wr=1'b0;
    assign inst_sram_size=2'd2;
    assign inst_sram_wdata=32'b0;
    assign inst_sram_wstrb=4'b0;
    // pipeline_is_stalled_from_tlb_csr prevents deadlock when tlb_csr_we flag
    // persists in drained pipeline registers after the CSR/TLB instruction has retired
    wire pipeline_drained_except_if = (id_pc == 32'b0) && (exe1_pc == 32'b0) && (mem_pc == 32'b0);
    wire cache_op_in_pipeline;
    assign cache_op_in_pipeline = (if_inst[31:22] == 10'b0000011000) ||
                                   (id_inst[31:22] == 10'b0000011000) ||
                                   (exe1_inst[31:22] == 10'b0000011000) ||
                                   (exe2_inst[31:22] == 10'b0000011000) ||
                                   (mem_inst[31:22] == 10'b0000011000) ||
                                   (wb_inst[31:22] == 10'b0000011000);

    assign inst_sram_req= if_allow_in & inst_req_valid & pc_inst_en & (~pipline_is_not_stalled===1'b0) & (!(inst_tlb_or_csr_we === 1'b1) | pipeline_drained_except_if) & (!cache_op_in_pipeline | pipeline_drained_except_if);

    wire if_allow_in;
    wire id_allow_in;
    wire exe1_allow_in;
    wire exe2_allow_in;
    wire mem_allow_in;
    wire wb_allow_in;
    wire [31:0]csr_era_pc;
    wire rst;
    wire [31:0] pc_br_target;
    wire pc_br_taken;
    wire [31:0]pc_inst_addr;
    assign pc_inst_addr = inst_sram_addr;
    wire pc_inst_en;
    wire [31:0] if_pc;
    assign rst = ~aresetn;
    wire inst_req_valid;
    wire wb_ready_go;
    wire if_ready_go;
    wire id_ready_go;
    wire exe1_ready_go;
    wire exe2_ready_go;
    wire mem_ready_go;
    wire pre_if_ready_go;
    wire [1:0]id_need_cancel_raw;      //下一条流入id_stage的指令需要取�???
    //wire if_allow_in;
    wire pipline_is_not_stalled;
    wire id_inst_cancel;
    wire exe2_addr_shake_ok;
    wire mem_data_shake_ok;
    wire IF_ready_go;
    wire ID_ready_go;
    wire EXE2_ready_go;
    wire mem_need_and_data_ok;
    wire [4:0] rf_raddr1;
    wire [4:0] rf_raddr2;
    wire [31:0] rf_wdata;
    wire [31:0] rf_rdata1;
    wire [31:0] rf_rdata2;
    wire [31:0] inst_addr;   // 经过TLB转换后的地址
    wire [1:0]  inst_mat;
    wire        inst_uncached;
    wire inst_dmw0_en;
    wire inst_dmw1_en;
    wire [1:0]inst_tlb_ex;
    wire if_tlb_or_csr_we;
    wire inst_tlb_or_csr_we;
    wire [1:0] if_inst_tlb_ex;

    assign inst_tlb_ex = ((csr_crmd_da && csr_crmd_pg==1'b0)|| inst_dmw0_en || inst_dmw1_en) ? 2'h0 :
                         (tlb_s0_found == 1'b0)                                              ? 2'h1 :
                         (tlb_s0_v == 1'b0)                                                  ? 2'h2 :
                         (tlb_s0_plv < csr_crmd_plv)                                         ? 2'h3 : 2'h0;

    assign inst_dmw0_en = csr_crmd_da == 1'b0 && csr_crmd_pg && ((csr_crmd_plv == 2'h3 && csr_dmw0_plv3)||(csr_crmd_plv == 2'h0 && csr_dmw0_plv0)) && inst_sram_addr[31:29] == csr_dmw0_vseg;
    assign inst_dmw1_en = csr_crmd_da == 1'b0 && csr_crmd_pg && ((csr_crmd_plv == 2'h3 && csr_dmw1_plv3)||(csr_crmd_plv == 2'h0 && csr_dmw1_plv0)) && inst_sram_addr[31:29] == csr_dmw1_vseg;
    assign inst_addr = (csr_crmd_da && csr_crmd_pg==1'b0) ?  inst_sram_addr :
                        inst_dmw0_en                       ?  {csr_dmw0_pseg,inst_sram_addr[28:0]} :
                        inst_dmw1_en                       ?  {csr_dmw1_pseg,inst_sram_addr[28:0]} :  {tlb_s0_ppn[19:0],inst_sram_addr[11:0]};
    assign inst_mat  = (csr_crmd_da && csr_crmd_pg==1'b0) ?  csr_crmd_datf :
                        inst_dmw0_en                       ?  csr_dmw0_mat :
                        inst_dmw1_en                       ?  csr_dmw1_mat : tlb_s0_mat;
    assign inst_uncached = ~inst_mat[0];


    // === BTB: simple branch target buffer ===
    wire        btb_hit;
    wire [31:0] btb_target;
    wire        btb_update;
    reg         predicted_taken;  // pipelined BTB hit flag

    reg btb_hit_d1;  // BTB hit when THIS instruction was fetched (pipelined)
    always @(posedge clk) begin
        if (rst) begin
            predicted_taken <= 1'b0;
            btb_hit_d1 <= 1'b0;
        end else if (!(if_ready_go===1'b0) && id_allow_in) begin
            predicted_taken <= btb_hit;
            btb_hit_d1 <= btb_hit;
        end
    end

    btb u_btb(
        .clk            (clk),
        .rst            (rst),
        .lookup_pc      (pc_inst_addr),
        .hit            (btb_hit),
        .target         (btb_target),
        .update         (id_br_taken),
        .update_pc      (id_pc),
        .update_target  (id_br_target)
    );

    // BTB misprediction: predicted taken but branch not taken
    wire btb_mispredict;
    assign btb_mispredict = predicted_taken && !id_br_taken;

    PC_Reg pc_reg(
        .clk(clk),
        .rst(rst),
        .if_allow_in(if_allow_in),
        .wb_ready_go(wb_ready_go),
        .pre_if_ready_go(pre_if_ready_go),
        .pipline_is_not_stalled(pipline_is_not_stalled),
        .if_pc(if_pc),
        .wb_ex(wb_ex),
        .inst_en(pc_inst_en),
        .pc_br_taken(pc_br_taken),
        .pc_br_target(pc_br_target),
        .inst_addr(inst_sram_addr),
        .inst_tlb_ex(inst_tlb_ex),
        .if_inst_tlb_ex(if_inst_tlb_ex),
        .btb_hit(btb_hit),
        .btb_target(btb_target),
        .wb_is_ertn(wb_is_ertn),
        .csr_era_pc(csr_era_pc)
    );


    assign if_tlb_or_csr_we =  (if_inst[31:24] == 8'h4  &&  if_inst[9:5] != 5'b0 ) ||
                            (if_inst[31:13] == 29'b0000011001001000001 || if_inst[31:15]==17'b00000110010010011);

    assign inst_tlb_or_csr_we = if_tlb_or_csr_we | id_tlb_or_csr_we | exe2_tlb_or_csr_we | mem_tlb_or_csr_we | wb_tlb_or_csr_we ;


    wire [31:0] id_inst;
    wire [31:0] exe1_inst;
    wire        exe1_dropped;
    wire [31:0] exe2_inst;
    wire [31:0] mem_inst;
    wire [31:0] wb_inst;
    wire [31:0] id_pc;
    wire [31:0] if_inst;
    wire ID_need_cancel;
    wire [1:0] id_inst_tlb_ex;
    // ID级中断标记信号
    wire id_has_int;
    wire [5:0] id_int_ecode;
    wire [7:0] id_int_esubcode;

    ID_Reg id_reg(
        .clk(clk),
        .rst(rst),
        .wb_is_ertn(wb_is_ertn),
        .mem_is_ertn(mem_is_ertn),
        .if_ready_go(if_ready_go),
        .exe_allow_in(exe1_allow_in),
        .exe_addr_shake_ok(exe2_addr_shake_ok),
        .exe_data_ram_req(data_sram_req),
        .exe_data_ram_addr_ok(data_sram_addr_ok),
        .id_inst_cancel(id_inst_cancel),
        .pipline_is_not_stalled(pipline_is_not_stalled),
        .id_allow_in(id_allow_in),
        .id_need_cancel(id_need_cancel),
        .if_pc(if_pc),
        .if_inst(if_inst),
        .id_inst(id_inst),
        .id_pc(id_pc),
        .wb_ex(wb_ex),
        .ID_need_cancel(ID_need_cancel),
        .if_inst_tlb_ex(if_inst_tlb_ex),
        .id_inst_tlb_ex(id_inst_tlb_ex),
        .int_has_int(int_has_int),
        .int_ecode(int_ecode),
        .int_esubcode(int_esubcode),
        .id_has_int(id_has_int),
        .id_int_ecode(id_int_ecode),
        .id_int_esubcode(id_int_esubcode)
    );
    reg [31:0] inst_sram_rdata_safe;
    reg        br_need_cancel;
    reg [31:0] br_delay_slot_pc;

    always @(posedge clk) begin
        if (rst)
            inst_sram_rdata_safe <= 32'h02800000;
        else if (real_inst_data_ok)
            inst_sram_rdata_safe <= inst_sram_rdata;
    end

    always @(posedge clk) begin
        if (rst || wb_is_ertn || wb_ex) begin
            br_need_cancel <= 1'b0;
            br_delay_slot_pc <= 32'b0;
        end else if (id_br_taken_safe) begin
            br_need_cancel <= 1'b1;
            br_delay_slot_pc <= id_pc + 32'd4;
        end else if (br_need_cancel && !(if_ready_go===1'b0) && id_allow_in && if_pc == br_delay_slot_pc) begin
            br_need_cancel <= 1'b0;
        end
    end

    assign if_inst = rst ? 32'h02800000 :
                     ((id_br_taken_safe) || br_need_cancel) ? 32'h02800000 :
                     real_inst_data_ok ? inst_sram_rdata : inst_sram_rdata_safe;

    // DEBUG: verify post-redirect fetch
    reg dbg_redirected;
    always @(posedge clk) begin
        if (rst)                              dbg_redirected <= 1'b0;
        else if (wb_ex || wb_is_ertn)         dbg_redirected <= 1'b1;
        else if (inst_sram_data_ok && inst_sram_addr_ok)           dbg_redirected <= 1'b0;
    end
    always @(posedge clk) begin
        if (!rst && dbg_redirected)
            $display("[POST-EX] %0t: id_inst=%h id_need_cancel=%b if_inst=%h if_pc=%h data_ok=%h pre_if_ready_go=%b rdata=%h if_inst=%h next_addr=%h",
                $time, id_inst, id_need_cancel, if_inst, if_pc,
                inst_sram_data_ok && inst_sram_addr_ok, pre_if_ready_go, inst_sram_rdata, if_inst, inst_sram_addr);
    end

    // === BTB update on id_br_taken ===
    wire [31:0]id_src1;
    wire [31:0]id_src2;
    wire id_ref_we;
    wire [4:0]id_alu_op;
    wire id_dram_we;
    wire id_dram_re;
    wire [4:0]id_rd;
    wire [4:0]id_rj;
    wire [4:0]id_rk;
    wire id_src2_is_imm12;
    wire [11:0]id_imm12;
    wire [4:0]id_imm5;
    wire id_src2_is_imm5;
    wire id_src2_is_rd;
    wire [15:0] id_imm16;
    wire [25:0] id_imm26;
    wire id_src2_is_imm26;
    wire id_src2_is_imm16;
    wire id_res_from_dram;
    wire [31:0] id_dram_wdata;
    wire [19:0] id_imm20;
    wire id_src2_is_imm20;
   // wire id_cancel;   //跳转的话，需要置�???????1
    wire id_br_taken;
    wire id_br_taken_safe;
    assign id_br_taken_safe = id_br_taken && pipline_is_not_stalled;
    wire [31:0]id_br_target;
    wire id_src1_from_ref;
    wire id_src2_from_ref;
    wire id_zero_extend; //如果第二个操作数是立即数，�?�且�????要零扩展，是的话�????1，否则的话为0
    wire id_rdram_need_zero_extend;
    wire id_rdram_need_signed_extend;
    wire [1:0]id_rdram_num; //如果是ld类指令，ld.w�????0，ld.b,ld.bu�????1，ld.h,ld.hu�????2
    wire [1:0]id_wdram_num; //如果是st类指令，st.w�????0，ld.b,ld.bu�????1，ld.h,ld.hu�????2

    wire [13:0] id_csr_num;
    wire id_csr_we;
    wire id_is_ertn;
    wire id_is_syscall;
    wire id_res_from_csr;
    wire [31:0]id_csr_wdata;
    wire [31:0]id_csr_wmask;
    wire id_csr_mask_all_one;
    wire id_ex_adef;
    wire id_ex_brk;
    wire id_ex_ine;
    wire id_ex_ale_h;
    wire id_ex_ale_w;
    wire [63:0] csr_tid_tid;
    wire [63:0] csr_timer_64;
    wire [31:0] id_res_of_cnt;
    wire id_res_from_cnt;
    //wire [31:0]id_csr_rdata;
    wire id_res_from_tid;
    wire id_need_data_sram;
    wire id_inst_tlbrd;
    wire id_tlb_we;
    wire id_inst_tlbsrch;
    wire id_tlb_wr_en;
    wire id_tlb_fill_en;
    wire id_invtlb_valid;
    wire [4:0]id_invtlb_op;
    wire [9:0]id_invtlb_asid;
    wire [18:0]id_invtlb_va;
    wire id_is_st;
    wire id_is_ld;
    wire id_tlb_or_csr_we;


    // interrupt.v 实例化 - 中断检测模块
    wire int_has_int;
    wire [5:0] int_ecode;
    wire [7:0] int_esubcode;

    interrupt u_interrupt(
        .clk(clk),
        .rst(rst),
        .csr_estat_is(csr_estat_is),
        .csr_ecfg_lie(csr_ecfg_lie),
        .csr_crmd_ie(csr_crmd_ie),
        .ext_intrpt(intrpt),
        .int_has_int(int_has_int),         //来自interrupt.v的中断标记
        .int_ecode(int_ecode),
        .int_esubcode(int_esubcode)
    );

    ID_stage id_stage(
        .id_inst(id_inst),    //Input:输入的指�????
        .id_pc(id_pc),        //Input:当前指令的pc
        .csr_timer_64(csr_timer_64),       //新增�????64位计数器的数�????
        .int_has_int(int_has_int),         //来自interrupt.v的中断标记
       // .csr_tid_tid(csr_tid_tid),         //新增�????64位计数器的编�????
        .id_rj(id_rj),        //output：寄存器rj的地�????
        .id_rk(id_rk),        //output：rk的地�????
        .id_rd(id_rd),        //output：rd的地�????，记得指令为bl时将id_rd设置�????1(已实�????)
        .id_rf_rdata1(rf_rdata1),     //Input：从寄存器读到的源操作数1�????
        .id_rf_rdata2(rf_rdata2),     //Input:从寄存器读到的源操作�????2,
        .id_ref_we(id_ref_we),        //Output:是否�????要写寄存�????
        .id_alu_op(id_alu_op),        //Output:alu的op信号，对照表在word�????
        .id_dram_we(id_dram_we),      //Output(下边的都是output):是否�????要写dram
        .id_dram_re(id_dram_re),      //是否�????要读dram
        .id_src2_is_imm12(id_src2_is_imm12),         //以下为立即数的控制信�????
        .id_imm12(id_imm12),
        .id_imm5(id_imm5),
        .id_src2_is_imm5(id_src2_is_imm5),
        .id_src2_is_rd(id_src2_is_rd),
        .id_imm16(id_imm16),
        .id_imm26(id_imm26),
        .id_src2_is_imm26(id_src2_is_imm26),
        .id_src2_is_imm16(id_src2_is_imm16),
        .id_res_from_dram(id_res_from_dram),
        .id_src2_is_imm20(id_src2_is_imm20),
        .id_imm20(id_imm20),
        .id_br_taken(id_br_taken),                //是否�????要跳�????
        .id_br_target(id_br_target),              //跳转的地�????，（由于流水线要处理冒险，故我把跳转模块从exe_stage挪到了id_stage�????)
        .id_src1_from_ref(id_src1_from_ref),      //�????1个源操作数是否来自寄存器堆，
        .id_src2_from_ref(id_src2_from_ref),      //�????2个源操作数是否来自寄存器堆，这个和id_src1_from_ref的生成方法要看下"exp8-9"word,
        .id_zero_extend(id_zero_extend),          //src2是立即数的话，是�????要符号扩展还是零扩展，零扩展的话�????1
        .id_rdram_need_zero_extend(id_rdram_need_zero_extend),
        .id_rdram_need_signed_extend(id_rdram_need_signed_extend),  //�????3个信号是ld类指令，�????要将dada_ram数据写入寄存器堆时，对data_ram中读到的数据的处理信�????
        .id_rdram_num(id_rdram_num),             //如果是ld类指令，ld.w�????0，ld.b,ld.bu�????1，ld.h,ld.hu�????2
        .id_wdram_num(id_wdram_num),              //如果是st类指令，st.w�????0，ld.b,ld.bu�????1，ld.h,ld.hu�????2

        .id_csr_num(id_csr_num),                   //csr读地�????或�?�写地址
        .id_csr_we(id_csr_we),                     //csr写使�????
        .id_is_ertn(id_is_ertn) ,                 //是否是ertn
        .id_is_syscall(id_is_syscall) ,           //是否是系统调用异�????
        .id_res_from_csr(id_res_from_csr),     //与id_res_from_dram类似，这里最后要写回通用寄存器的数据可能来自csr寄存器，是的话置1
        .id_csr_mask_all_one(id_csr_mask_all_one),       //csrxchg指令�????0，其余是1
        .id_ex_adef(id_ex_adef),                         //�????测取指令的地�????错了没？即最低两位不�????00的话赋�?�为1
        .id_ex_brk(id_ex_brk),                          //与syscall指令类似，只要译码出来是break指令，就�????1
        .id_ex_ine(id_ex_ine),                           //指令地址虽然正确，但取出来的指令不存�????,不是任何�????条指�????
        .id_ex_ale_h(id_ex_ale_h),                       //ld.h,ld.hu,st.h时置1
        .id_ex_ale_w(id_ex_ale_w),                      // ld.w,st.w时置1，这两条信号是为了方便之后exe级检测地�????不对齐异�????
        .id_has_int(),                       //�????测中断，在书�????7.2.1节有示例，注意前边多�????3个来自csr的输入信号需要补�????
        .id_res_is_rj(id_res_is_rj),                   //只对应rdcntid指令，写寄存器的地址是rj
        .id_res_of_cnt(id_res_of_cnt),                  //对应三个将counter64相关数据写入寄存器的指令，如果是那三个指令，就输出要写入寄存器堆的数�????
        .id_res_from_cnt(id_res_from_cnt),              //对应上边三个指令时为1
        .id_res_from_tid(id_res_from_tid),
        .id_need_data_sram(id_need_data_sram) ,         //对应load,store类指�???
        .id_inst_tlbrd(id_inst_tlbrd),                    //表示是tlbrd指令
        .id_tlb_we(id_tlb_we),                            //tlb的写使能
        .id_invtlb_op(id_invtlb_op),            //invtlb指令的op�??
        .id_invtlb_valid(id_invtlb_valid),              //invtlb指令有效
        .id_inst_tlbsrch(id_inst_tlbsrch),                //表示是inst_tlbsrch指令
        .id_tlb_wr_en(id_tlb_wr_en),
        .id_tlb_fill_en(id_tlb_fill_en),
        .id_is_st(id_is_st),
        .id_is_ld(id_is_ld),
        .id_tlb_or_csr_we(id_tlb_or_csr_we)
    );
    assign id_dram_wdata=id_src2;
    // ERTN behaves like a branch in ID: redirect PC to ERA immediately,
    // preventing PC+8 from being fetched. Delay slot (already in IF) still executes.
    assign pc_br_taken=id_br_taken_safe|(id_is_ertn==1'b1)|btb_mispredict;
    assign pc_br_target =    btb_mispredict ? (id_pc + 32'd4) :
                            (wb_is_ertn===1'b1 || id_is_ertn===1'b1)  ?   csr_era_pc  :
                            (csr_data_tlb_refill || csr_inst_tlb_refill) ? {csr_tlbrentry, 6'b0}  :
                            wb_ex===1'b1      ?   csr_rvalue  :  id_br_target;
    wire [31:0] id_src2_fwd;
    assign id_src2_fwd = (exe1_ref_we && exe1_rd == rf_raddr2 && rf_raddr2 != 5'd0) ? exe1_alu_result :
                         (exe2_ref_we && exe2_rd == rf_raddr2 && rf_raddr2 != 5'd0) ? exe2_alu_result :
                         (mem_ref_we  && mem_rd  == rf_raddr2 && rf_raddr2 != 5'd0) ? mem_alu_result  :
                         (wb_rf_we    && wb_rd   == rf_raddr2 && rf_raddr2 != 5'd0) ? rf_wdata         :
                         rf_rdata2;
    assign id_csr_wdata = id_src2_fwd;
    wire [31:0] id_src1_fwd;
    assign id_src1_fwd = (exe1_ref_we && exe1_rd == rf_raddr1 && rf_raddr1 != 5'd0) ? exe1_alu_result :
                         (exe2_ref_we && exe2_rd == rf_raddr1 && rf_raddr1 != 5'd0) ? exe2_alu_result :
                         (mem_ref_we  && mem_rd  == rf_raddr1 && rf_raddr1 != 5'd0) ? mem_alu_result  :
                         (wb_rf_we    && wb_rd   == rf_raddr1 && rf_raddr1 != 5'd0) ? rf_wdata         :
                         rf_rdata1;
    assign id_csr_wmask = id_csr_mask_all_one? 32'hffffffff : id_src1_fwd;

    // DEBUG: csrwr forwarding trace
    wire is_csrwr = (id_inst[31:24] == 8'h04) && (id_inst[25:24] == 2'b00) && (id_inst[9:5] == 5'd1);
    always @(posedge clk) begin
        if (!rst && (is_csrwr || id_csr_we)) begin
            $display("[CSR-FWD] %0t: id_inst=%h csrwe=%b src2_fwd=%h rf_raddr2=%d rf_rdata2=%h",
                $time, id_inst, id_csr_we, id_src2_fwd, rf_raddr2, rf_rdata2);
            $display("[CSR-FWD]   exe1_rwe=%b exe1_rd=%d exe1_res=%h exe2_rwe=%b exe2_rd=%d exe2_res=%h",
                exe1_ref_we, exe1_rd, exe1_alu_result, exe2_ref_we, exe2_rd, exe2_alu_result);
            $display("[CSR-FWD]   mem_rwe=%b  mem_rd=%d  mem_res=%h  wb_rwe=%b   wb_rd=%d  wb_res=%h",
                mem_ref_we, mem_rd, mem_alu_result, wb_rf_we, wb_rd, rf_wdata);
        end
    end
    // DEBUG: track exe1_csr_wdata when it captures csrwr
    always @(posedge clk) begin
        if (!rst && exe1_csr_we)
            $display("[CSR-EXE1] %0t: exe1_csr_wdata=%h exe1_pc=%h",
                $time, exe1_csr_wdata, exe1_pc);
    end
    always @(posedge clk) begin
        if (!rst && wb_csr_we)
            $display("[CSR-WB] %0t: wb_csr_wdata=%h wb_csr_num=%d wb_ex=%b wb_pc=%h",
                $time, wb_csr_wdata, wb_csr_num, wb_ex, wb_pc);
    end

    assign id_invtlb_asid = rf_rdata1[9:0];
    assign id_invtlb_va = rf_rdata2[31:13];
    //assign id_csr_rdata=csr_rvalue;
    // ---- EXE1 stage wires (outputs from ExE1_reg) ----
    wire [31:0]exe1_src1;
    wire [4:0]exe1_rd;
    wire [31:0]exe1_src2;
    wire exe1_ref_we;
    wire [4:0]exe1_alu_op;
    wire exe1_dram_we;
    wire exe1_dram_re;
    wire [11:0] exe1_imm12;
    wire exe1_src2_is_imm12;
    wire [4:0] exe1_imm5;
    wire exe1_src2_is_imm5;
    wire [31:0] exe1_pc;
    wire [15:0] exe1_imm16;
    wire exe1_src2_is_imm26;
    wire [25:0]exe1_imm26;
    wire exe1_src2_is_imm16;
    wire exe1_res_from_dram;
    wire [31:0] exe1_dram_wdata;
    wire [19:0] exe1_imm20;
    wire exe1_src2_is_imm20;
    wire [31:0] exe1_rf_src1;
    wire [31:0] exe1_rf_src2;
    wire exe1_zero_extend;
    wire exe1_rdram_need_zero_extend;
    wire exe1_rdram_need_signed_extend;
    wire [1:0]exe1_rdram_num;
    wire [1:0]exe1_wdram_num;
    wire [13:0] exe1_csr_num;
    wire exe1_csr_we;
    wire exe1_is_ertn;
    wire exe1_is_syscall;
    wire exe1_res_from_csr;
    wire [31:0] exe1_csr_wmask;
    wire [31:0] exe1_csr_wdata;
    wire exe1_ex_ale_h;
    wire exe1_ex_ale_w;
    wire exe1_ex_adef;
    wire exe1_ex_brk;
    wire exe1_ex_ine;
    wire exe1_has_int;
    wire [4:0]exe1_rj;
    wire [31:0]exe1_res_of_cnt;
    wire exe1_res_is_rj;
    wire exe1_res_from_cnt;
    wire exe1_res_from_tid;
    wire exe1_need_data_sram;
    wire exe1_need_cancel;
    wire exe1_inst_tlbrd;
    wire exe1_inst_tlbsrch;
    wire exe1_tlb_wr_en;
    wire exe1_tlb_fill_en;
    wire exe1_tlb_we;
    wire exe1_invtlb_valid;
    wire [4:0]exe1_invtlb_op;
    wire [9:0]exe1_invtlb_asid;
    wire [18:0]exe1_invtlb_va;
    wire exe1_is_st;
    wire exe1_is_ld;
    wire exe1_tlb_or_csr_we;
    wire [1:0]exe1_inst_tlb_ex;
    wire [5:0] exe1_int_ecode;
    wire [7:0] exe1_int_esubcode;
    wire exe1_div_is_doing;
    // ---- EXE2 stage wires (outputs from ExE2_reg) ----
    wire [31:0]exe2_src1;
    wire [4:0]exe2_rd;
    wire [31:0]exe2_src2;
    wire exe2_ref_we;
    wire [4:0]exe2_alu_op;
    wire exe2_dram_we;
    wire exe2_dram_re;
    wire [11:0] exe2_imm12;
    wire exe2_src2_is_imm12;
    wire [4:0] exe2_imm5;
    wire exe2_src2_is_imm5;
    wire [31:0] exe2_pc;
    wire [15:0] exe2_imm16;
    wire exe2_src2_is_imm26;
    wire [25:0]exe2_imm26;
    wire exe2_src2_is_imm16;
    wire exe2_res_from_dram;
    wire [31:0] exe2_dram_wdata;
    wire [19:0] exe2_imm20;
    wire exe2_src2_is_imm20;
    wire [31:0] exe2_rf_src1;
    wire [31:0] exe2_rf_src2;
    wire exe2_zero_extend;
    wire exe2_rdram_need_zero_extend;
    wire exe2_rdram_need_signed_extend;
    wire [1:0]exe2_rdram_num;
    wire [1:0]exe2_wdram_num;
    wire [13:0] exe2_csr_num;
    wire exe2_csr_we;
    wire exe2_is_ertn;
    wire exe2_is_syscall;
    wire exe2_res_from_csr;
    wire [31:0] exe2_csr_wmask;
    wire [31:0] exe2_csr_wdata;
    wire exe2_ex_ale_h;
    wire exe2_ex_ale_w;
    wire exe2_ex_adef;
    wire exe2_ex_brk;
    wire exe2_ex_ine;
    wire exe2_has_int;
    wire [4:0]exe2_rj;
    wire [31:0]exe2_res_of_cnt;
    wire exe2_res_is_rj;
    wire exe2_res_from_cnt;
    wire exe2_res_from_tid;
    wire exe2_need_data_sram;
    wire exe2_need_cancel;
    wire exe2_inst_tlbrd;
    wire exe2_inst_tlbsrch;
    wire exe2_tlb_wr_en;
    wire exe2_tlb_fill_en;
    wire exe2_tlb_we;
    wire exe2_invtlb_valid;
    wire [4:0]exe2_invtlb_op;
    wire [9:0]exe2_invtlb_asid;
    wire [18:0]exe2_invtlb_va;
    wire exe2_is_st;
    wire exe2_is_ld;
    wire exe2_tlb_or_csr_we;
    wire [1:0]exe2_inst_tlb_ex;
    wire [5:0] exe2_int_ecode;
    wire [7:0] exe2_int_esubcode;


    //wire [31:0]exe_csr_rdata;
    ExE1_reg exe1_reg(
        .clk(clk),
        .rst(rst),
        .wb_ex(wb_ex),
        .wb_is_ertn(wb_is_ertn),
        .mem_is_ertn(mem_is_ertn),
        .exe1_div_is_doing(exe1_div_is_doing),
        .exe1_ready_go(exe1_ready_go),
        .id_ready_go(id_ready_go),
        .exe1_allow_in(exe1_allow_in),
        .exe2_allow_in(exe2_allow_in),
        .id_rd(id_rd),
        .id_src1(id_src1),
        .id_src2(id_src2),
        .id_ref_we(id_ref_we),
        .id_alu_op(id_alu_op),
        .id_dram_re(id_dram_re),
        .id_dram_we(id_dram_we),
        .id_imm12(id_imm12),
        .id_src2_is_imm12(id_src2_is_imm12),
        .id_src2_is_imm5(id_src2_is_imm5),
        .id_imm5(id_imm5),
        .id_pc(id_pc),
        .id_imm16(id_imm16),
        .id_imm26(id_imm26),
        .id_src2_is_imm26(id_src2_is_imm26),
        .id_src2_is_imm16(id_src2_is_imm16),
        .id_res_from_dram(id_res_from_dram),
        .id_dram_wdata(id_dram_wdata),
        .id_imm20(id_imm20),
        .id_src2_is_imm20(id_src2_is_imm20),
        .id_zero_extend(id_zero_extend),
        .id_rdram_need_zero_extend(id_rdram_need_zero_extend),
        .id_rdram_need_signed_extend(id_rdram_need_signed_extend),
        .id_rdram_num(id_rdram_num),
        .id_wdram_num(id_wdram_num),
        .id_csr_num(id_csr_num),
        .id_csr_we(id_csr_we),
        .id_is_ertn(id_is_ertn),
        .id_is_syscall(id_is_syscall),
        .id_res_from_csr(id_res_from_csr),
        .id_csr_wmask(id_csr_wmask),
        .id_csr_wdata(id_csr_wdata),
        .id_ex_adef(id_ex_adef),
        .id_ex_brk(id_ex_brk),
        .id_ex_ine(id_ex_ine),
        .id_ex_ale_h(id_ex_ale_h),
        .id_ex_ale_w(id_ex_ale_w),
        .id_has_int(id_has_int),
        .id_int_ecode(id_int_ecode),
        .id_int_esubcode(id_int_esubcode),
        .id_rj(id_rj),
        .id_res_of_cnt(id_res_of_cnt),
        .id_res_is_rj(id_res_is_rj),
        .id_res_from_cnt(id_res_from_cnt),
        .id_res_from_tid(id_res_from_tid),
        .id_need_data_sram(id_need_data_sram),
        .id_need_cancel(ID_need_cancel),
        .id_inst_tlbrd(id_inst_tlbrd),
        .id_inst_tlbsrch(id_inst_tlbsrch),
        .id_tlb_wr_en(id_tlb_wr_en),
        .id_tlb_we(id_tlb_we),
        .id_tlb_fill_en(id_tlb_fill_en),
        .id_invtlb_asid(id_invtlb_asid),
        .id_invtlb_op(id_invtlb_op),
        .id_invtlb_va(id_invtlb_va),
        .id_invtlb_valid(id_invtlb_valid),
        .id_is_st(id_is_st),
        .id_is_ld(id_is_ld),
        .id_tlb_or_csr_we(id_tlb_or_csr_we),
        .id_inst_tlb_ex(id_inst_tlb_ex),
        .id_inst(id_inst),
        //.id_csr_rdata(id_csr_rdata),
        .exe1_rd(exe1_rd),
        .exe1_src1(exe1_src1),
        .exe1_src2(exe1_src2),
        .exe1_ref_we(exe1_ref_we),
        .exe1_alu_op(exe1_alu_op),
        .exe1_dram_re(exe1_dram_re),
        .exe1_dram_we(exe1_dram_we),
        .exe1_imm12(exe1_imm12),
        .exe1_src2_is_imm12(exe1_src2_is_imm12),
        .exe1_pc(exe1_pc),
        .exe1_imm16(exe1_imm16),
        .exe1_imm5(exe1_imm5),
        .exe1_src2_is_imm5(exe1_src2_is_imm5),
        .exe1_src2_is_imm26(exe1_src2_is_imm26),
        .exe1_imm26(exe1_imm26),
        .exe1_src2_is_imm16(exe1_src2_is_imm16),
        .exe1_res_from_dram(exe1_res_from_dram),
        .exe1_dram_wdata(exe1_dram_wdata),
        .exe1_imm20(exe1_imm20),
        .exe1_src2_is_imm20(exe1_src2_is_imm20),
        .exe1_rf_src1(exe1_rf_src1),
        .exe1_rf_src2(exe1_rf_src2),
        .exe1_zero_extend(exe1_zero_extend),
        .exe1_rdram_need_zero_extend(exe1_rdram_need_zero_extend),
        .exe1_rdram_need_signed_extend(exe1_rdram_need_signed_extend),
        .exe1_rdram_num(exe1_rdram_num),
        .exe1_wdram_num(exe1_wdram_num),
        .exe1_csr_num(exe1_csr_num),
        .exe1_csr_we(exe1_csr_we),
        .exe1_is_ertn(exe1_is_ertn),
        .exe1_is_syscall(exe1_is_syscall),
        .exe1_res_from_csr(exe1_res_from_csr),
        .exe1_csr_wmask(exe1_csr_wmask),
        .exe1_csr_wdata(exe1_csr_wdata),
        .exe1_ex_adef(exe1_ex_adef),
        .exe1_ex_brk(exe1_ex_brk),
        .exe1_ex_ine(exe1_ex_ine),
        .exe1_ex_ale_h(exe1_ex_ale_h),
        .exe1_ex_ale_w(exe1_ex_ale_w),
        .exe1_has_int(exe1_has_int),
        .exe1_int_ecode(exe1_int_ecode),
        .exe1_int_esubcode(exe1_int_esubcode),
        .exe1_rj(exe1_rj),
        .exe1_res_of_cnt(exe1_res_of_cnt),
        .exe1_res_is_rj(exe1_res_is_rj),
        .exe1_res_from_cnt(exe1_res_from_cnt),
        .exe1_res_from_tid(exe1_res_from_tid),
        .exe1_need_data_sram(exe1_need_data_sram),
        .exe1_need_cancel(exe1_need_cancel),
        .exe1_inst_tlbrd(exe1_inst_tlbrd),
        .exe1_inst_tlbsrch(exe1_inst_tlbsrch),
        .exe1_tlb_we(exe1_tlb_we),
        .exe1_tlb_wr_en(exe1_tlb_wr_en),
        .exe1_tlb_fill_en(exe1_tlb_fill_en),
        .exe1_invtlb_asid(exe1_invtlb_asid),
        .exe1_invtlb_op(exe1_invtlb_op),
        .exe1_invtlb_va(exe1_invtlb_va),
        .exe1_invtlb_valid(exe1_invtlb_valid),
        .exe1_is_st(exe1_is_st),
        .exe1_is_ld(exe1_is_ld),
        .exe1_tlb_or_csr_we(exe1_tlb_or_csr_we),
        .exe1_inst_tlb_ex(exe1_inst_tlb_ex),
        .exe1_inst(exe1_inst),
        .exe1_dropped(exe1_dropped)
    );

    wire [31:0] exe1_alu_result;
    wire [31:0] alu_src1;
    wire [31:0] alu_src2;
    wire [31:0]exe1_br_target;
    wire exe1_br_taken;
    wire [17:0]exe1_imm16_extend;
    wire [27:0]exe1_imm26_extend;
    assign exe1_imm16_extend={exe1_imm16,2'b00};
    assign exe1_imm26_extend={exe1_imm26,2'b00};
    wire div_divsigned;
    wire div_completed;
    wire div_done;
    wire div_en;
    wire [31:0] div_result;
    wire [31:0] div_rest;
    wire [31:0] exe1_alu_ret;


    assign alu_src1=exe1_src1;
    assign alu_src2 = exe1_src2_is_imm12  ?  exe1_zero_extend?     {20'b0,exe1_imm12} :{{20{exe1_imm12[11]}}, exe1_imm12} :
                  exe1_src2_is_imm5   ? {{27{exe1_imm5[4]}}, exe1_imm5} :
                  exe1_src2_is_imm26  ?  {{4{exe1_imm26_extend[27]}}, exe1_imm26_extend}:
                  exe1_src2_is_imm16  ?  {{14{exe1_imm16_extend[17]}}, exe1_imm16_extend} :
                  exe1_src2_is_imm20  ? exe1_imm20 :
                                       exe1_src2;
    assign div_divsigned = exe1_alu_op == 5'd22 || exe1_alu_op == 5'd20;
    assign div_en = exe1_alu_op == 5'd20 || exe1_alu_op == 5'd21 || exe1_alu_op == 5'd22 || exe1_alu_op == 5'd23 ;
    assign exe1_div_is_doing = div_en && div_done==1'b0;

    ALU alu(
        .src1(alu_src1),
        .src2(alu_src2),
        .alu_op(exe1_alu_op),
        .exe_alu_result(exe1_alu_ret),
        .exe_pc(exe1_pc),
        .exe_br_taken(exe1_br_taken),
        .exe_br_target(exe1_br_target),
        .alu_rf_src1(exe1_rf_src1),
        .alu_rf_src2(exe1_rf_src2),
        .exe_ex_ale_h(exe1_ex_ale_h),
        .exe_ex_ale_w(exe1_ex_ale_w),
        .exe_ex_ale(exe1_ex_ale)       //exe_ex_ale_h�????1时，�????测运算结果最低位是否�????0，不是的话置1；exe_ex_ale_w�????0时，�????测运算结果低两位是否�????0，不是就�????1
    );//


    Div div(
        .div_clk(clk),
        .reset(rst),
        .div_signed(div_divsigned),
        .div(div_en),
        .x(alu_src1),
        .y(alu_src2),
        .s(div_result),
        .r(div_rest),
        .complete(div_completed),
        .div_done(div_done)
    );
    assign exe1_alu_result = (exe1_alu_op==5'd20 || exe1_alu_op == 5'd21) ?   div_result :
                            (exe1_alu_op==5'd22 || exe1_alu_op == 5'd23) ?   div_rest : exe1_alu_ret;

    // ---- EXE2 stage wires (computed from ALU outputs, passed through ExE2_reg) ----
    wire [31:0] exe2_alu_result;
    wire exe2_br_taken;
    wire [31:0] exe2_br_target;
    wire exe2_ex_ale;
    wire [31:0] exe2_data_addr;

    ExE2_reg exe2_reg(
        .clk(clk),
        .rst(rst),
        .wb_ex(wb_ex),
        .wb_is_ertn(wb_is_ertn),
        .exe1_ready_go(exe1_ready_go),
        .exe2_allow_in(exe2_allow_in),
        .mem_allow_in(mem_allow_in),
        .exe2_ready_go(exe2_ready_go),
        .exe2_addr_shake_ok(exe2_addr_shake_ok),
        .mem_data_shake_ok(mem_data_shake_ok),
        .mem_need_and_data_ok(mem_need_and_data_ok),

        .exe1_rd(exe1_rd),
        .exe1_src1(exe1_src1),
        .exe1_src2(exe1_src2),
        .exe1_ref_we(exe1_ref_we),
        .exe1_alu_op(exe1_alu_op),
        .exe1_dram_re(exe1_dram_re),
        .exe1_dram_we(exe1_dram_we),
        .exe1_imm12(exe1_imm12),
        .exe1_src2_is_imm12(exe1_src2_is_imm12),
        .exe1_src2_is_imm5(exe1_src2_is_imm5),
        .exe1_imm5(exe1_imm5),
        .exe1_pc(exe1_pc),
        .exe1_imm16(exe1_imm16),
        .exe1_imm26(exe1_imm26),
        .exe1_src2_is_imm26(exe1_src2_is_imm26),
        .exe1_src2_is_imm16(exe1_src2_is_imm16),
        .exe1_res_from_dram(exe1_res_from_dram),
        .exe1_dram_wdata(exe1_dram_wdata),
        .exe1_imm20(exe1_imm20),
        .exe1_src2_is_imm20(exe1_src2_is_imm20),
        .exe1_rf_src1(exe1_rf_src1),
        .exe1_rf_src2(exe1_rf_src2),
        .exe1_zero_extend(exe1_zero_extend),
        .exe1_rdram_need_zero_extend(exe1_rdram_need_zero_extend),
        .exe1_rdram_need_signed_extend(exe1_rdram_need_signed_extend),
        .exe1_rdram_num(exe1_rdram_num),
        .exe1_wdram_num(exe1_wdram_num),
        .exe1_csr_num(exe1_csr_num),
        .exe1_csr_we(exe1_csr_we),
        .exe1_is_ertn(exe1_is_ertn),
        .exe1_is_syscall(exe1_is_syscall),
        .exe1_res_from_csr(exe1_res_from_csr),
        .exe1_csr_wmask(exe1_csr_wmask),
        .exe1_csr_wdata(exe1_csr_wdata),
        .exe1_ex_adef(exe1_ex_adef),
        .exe1_ex_brk(exe1_ex_brk),
        .exe1_ex_ine(exe1_ex_ine),
        .exe1_ex_ale_h(exe1_ex_ale_h),
        .exe1_ex_ale_w(exe1_ex_ale_w),
        .exe1_has_int(exe1_has_int),
        .exe1_int_ecode(exe1_int_ecode),
        .exe1_int_esubcode(exe1_int_esubcode),
        .exe1_rj(exe1_rj),
        .exe1_res_of_cnt(exe1_res_of_cnt),
        .exe1_res_is_rj(exe1_res_is_rj),
        .exe1_res_from_cnt(exe1_res_from_cnt),
        .exe1_res_from_tid(exe1_res_from_tid),
        .exe1_need_data_sram(exe1_need_data_sram),
        .exe1_need_cancel(exe1_need_cancel),
        .exe1_inst_tlbrd(exe1_inst_tlbrd),
        .exe1_inst_tlbsrch(exe1_inst_tlbsrch),
        .exe1_tlb_wr_en(exe1_tlb_wr_en),
        .exe1_tlb_we(exe1_tlb_we),
        .exe1_tlb_fill_en(exe1_tlb_fill_en),
        .exe1_invtlb_asid(exe1_invtlb_asid),
        .exe1_invtlb_op(exe1_invtlb_op),
        .exe1_invtlb_va(exe1_invtlb_va),
        .exe1_invtlb_valid(exe1_invtlb_valid),
        .exe1_is_st(exe1_is_st),
        .exe1_is_ld(exe1_is_ld),
        .exe1_tlb_or_csr_we(exe1_tlb_or_csr_we),
        .exe1_inst_tlb_ex(exe1_inst_tlb_ex),
        .exe1_alu_result(exe1_alu_result),
        .exe1_br_taken(exe1_br_taken),
        .exe1_br_target(exe1_br_target),
        .exe1_ex_ale(exe1_ex_ale),
        .exe1_inst(exe1_inst),

        .exe2_rd(exe2_rd),
        .exe2_src1(exe2_src1),
        .exe2_src2(exe2_src2),
        .exe2_ref_we(exe2_ref_we),
        .exe2_alu_op(exe2_alu_op),
        .exe2_dram_re(exe2_dram_re),
        .exe2_dram_we(exe2_dram_we),
        .exe2_imm12(exe2_imm12),
        .exe2_src2_is_imm12(exe2_src2_is_imm12),
        .exe2_src2_is_imm5(exe2_src2_is_imm5),
        .exe2_imm5(exe2_imm5),
        .exe2_pc(exe2_pc),
        .exe2_imm16(exe2_imm16),
        .exe2_imm26(exe2_imm26),
        .exe2_src2_is_imm26(exe2_src2_is_imm26),
        .exe2_src2_is_imm16(exe2_src2_is_imm16),
        .exe2_res_from_dram(exe2_res_from_dram),
        .exe2_dram_wdata(exe2_dram_wdata),
        .exe2_imm20(exe2_imm20),
        .exe2_src2_is_imm20(exe2_src2_is_imm20),
        .exe2_rf_src1(exe2_rf_src1),
        .exe2_rf_src2(exe2_rf_src2),
        .exe2_zero_extend(exe2_zero_extend),
        .exe2_rdram_need_zero_extend(exe2_rdram_need_zero_extend),
        .exe2_rdram_need_signed_extend(exe2_rdram_need_signed_extend),
        .exe2_rdram_num(exe2_rdram_num),
        .exe2_wdram_num(exe2_wdram_num),
        .exe2_csr_num(exe2_csr_num),
        .exe2_csr_we(exe2_csr_we),
        .exe2_is_ertn(exe2_is_ertn),
        .exe2_is_syscall(exe2_is_syscall),
        .exe2_res_from_csr(exe2_res_from_csr),
        .exe2_csr_wmask(exe2_csr_wmask),
        .exe2_csr_wdata(exe2_csr_wdata),
        .exe2_ex_adef(exe2_ex_adef),
        .exe2_ex_brk(exe2_ex_brk),
        .exe2_ex_ine(exe2_ex_ine),
        .exe2_ex_ale_h(exe2_ex_ale_h),
        .exe2_ex_ale_w(exe2_ex_ale_w),
        .exe2_has_int(exe2_has_int),
        .exe2_int_ecode(exe2_int_ecode),
        .exe2_int_esubcode(exe2_int_esubcode),
        .exe2_rj(exe2_rj),
        .exe2_res_of_cnt(exe2_res_of_cnt),
        .exe2_res_is_rj(exe2_res_is_rj),
        .exe2_res_from_cnt(exe2_res_from_cnt),
        .exe2_res_from_tid(exe2_res_from_tid),
        .exe2_need_data_sram(exe2_need_data_sram),
        .exe2_need_cancel(exe2_need_cancel),
        .exe2_inst_tlbrd(exe2_inst_tlbrd),
        .exe2_inst_tlbsrch(exe2_inst_tlbsrch),
        .exe2_tlb_wr_en(exe2_tlb_wr_en),
        .exe2_tlb_we(exe2_tlb_we),
        .exe2_tlb_fill_en(exe2_tlb_fill_en),
        .exe2_invtlb_asid(exe2_invtlb_asid),
        .exe2_invtlb_op(exe2_invtlb_op),
        .exe2_invtlb_va(exe2_invtlb_va),
        .exe2_invtlb_valid(exe2_invtlb_valid),
        .exe2_is_st(exe2_is_st),
        .exe2_is_ld(exe2_is_ld),
        .exe2_tlb_or_csr_we(exe2_tlb_or_csr_we),
        .exe2_inst_tlb_ex(exe2_inst_tlb_ex),
        .exe2_alu_result(exe2_alu_result),
        .exe2_br_taken(exe2_br_taken),
        .exe2_br_target(exe2_br_target),
        .exe2_ex_ale(exe2_ex_ale),
        .exe2_inst(exe2_inst)
    );

    wire [31:0] mem_alu_result;
    wire  mem_ref_we;
    wire [4:0] mem_rd;
    wire mem_dram_re;
    wire mem_dram_we;
    //wire mem_br_taken;
    //wire [31:0] mem_br_target;
    wire mem_res_from_dram;
    wire [31:0] mem_dram_wdata;
    wire [31:0] mem_dram_waddr;
    wire [31:0] mem_pc;
    wire mem_rdram_need_zero_extend;
    wire mem_rdram_need_signed_extend;
    wire [1:0]mem_rdram_num;
    wire [1:0] mem_wdram_num;
    wire [31:0] mem_dram_rdata;
    wire [13:0] mem_csr_num;
    wire mem_csr_we;
    wire mem_is_ertn;
    wire mem_is_syscall;
    wire mem_res_from_csr;
    wire [31:0] mem_csr_wmask;
    wire [31:0] mem_csr_wdata;
    wire mem_ex_adef;
    wire mem_ex_ale;
    wire mem_ex_brk;
    wire mem_ex_ine;
    wire mem_has_int;
    wire [5:0] mem_int_ecode;
    wire [7:0] mem_int_esubcode;
    wire [4:0]mem_rj;
    wire [31:0]mem_res_of_cnt;
    wire mem_res_is_rj;
    wire mem_res_from_cnt;
    wire mem_res_from_tid;
    wire data_req_valid;
    wire mem_need_data_sram;//
    wire mem_ex_ale_h;
    wire mem_ex_ale_w;
    wire [31:0] exe2_dram_rdata;
    wire [31:0] mem_data_addr;
    wire mem_need_cancel;
    wire mem_inst_tlbrd;
    assign exe2_data_addr = data_sram_addr ;
    wire mem_inst_tlbsrch;
    wire mem_tlb_we;
    wire mem_tlb_fill_en;
    wire mem_tlb_wr_en;
    wire mem_invtlb_valid;
    wire [4:0]mem_invtlb_op;
    wire [9:0]mem_invtlb_asid;
    wire [18:0]mem_invtlb_va;
    wire [4:0] mem_alu_op;
    wire mem_tlb_or_csr_we;
    wire [1:0] mem_inst_tlb_ex;
    wire [2:0] mem_data_tlb_ex;

   // wire [31:0] mem_csr_rdata;
    Mem_reg mem_reg(
        .clk(clk),
        .rst(rst),
        .wb_ex(wb_ex),
        .wb_is_ertn(wb_is_ertn),
        .exe2_ready_go(exe2_ready_go),
        .mem_allow_in(mem_allow_in),
        .mem_data_shake_ok(mem_data_shake_ok),
        .exe2_alu_result(exe2_alu_result),
        .exe2_ref_we(exe2_ref_we),
        .exe2_dram_re(exe2_dram_re),
        .exe2_dram_we(exe2_dram_we),
        .exe2_data_addr(exe2_data_addr),
        .exe2_inst(exe2_inst),
        .exe2_rd(exe2_rd),
        //.exe2_br_taken(exe2_br_taken),
        //.exe2_br_target(exe2_br_target),
        .exe2_res_from_dram(exe2_res_from_dram),
        .exe2_dram_waddr(exe2_alu_result),
        .exe2_dram_wdata(exe2_dram_wdata),
        .exe2_pc(exe2_pc),
        .exe2_rdram_need_zero_extend(exe2_rdram_need_zero_extend),
        .exe2_rdram_need_signed_extend(exe2_rdram_need_signed_extend),
        .exe2_rdram_num(exe2_rdram_num),
        .exe2_wdram_num(exe2_wdram_num),
        .exe2_csr_num(exe2_csr_num),
        .exe2_csr_we(exe2_csr_we),
        .exe2_is_ertn(exe2_is_ertn),
        .exe2_is_syscall(exe2_is_syscall),
        .exe2_res_from_csr(exe2_res_from_csr),
        .exe2_csr_wmask(exe2_csr_wmask),
        .exe2_csr_wdata(exe2_csr_wdata),
        .exe2_ex_adef(exe2_ex_adef),
        .exe2_ex_brk(exe2_ex_brk),
        .exe2_ex_ine(exe2_ex_ine),
        .exe2_ex_ale(exe2_ex_ale),
        .exe2_has_int(exe2_has_int),
        .exe2_int_ecode(exe2_int_ecode),
        .exe2_int_esubcode(exe2_int_esubcode),
        .exe2_rj(exe2_rj),
        .exe2_res_of_cnt(exe2_res_of_cnt),
        .exe2_res_is_rj(exe2_res_is_rj),
        .exe2_res_from_cnt(exe2_res_from_cnt),
        .exe2_res_from_tid(exe2_res_from_tid),
        .exe2_need_data_sram(exe2_need_data_sram),
        .exe2_ex_ale_h(exe2_ex_ale_h),
        .exe2_ex_ale_w(exe2_ex_ale_w),
        .exe2_need_cancel(exe2_need_cancel),
        .exe2_inst_tlbrd(exe2_inst_tlbrd),
        .exe2_inst_tlbsrch(exe2_inst_tlbsrch),
        .exe2_tlb_wr_en(exe2_tlb_wr_en),
        .exe2_tlb_fill_en(exe2_tlb_fill_en),
        .exe2_tlb_we(exe2_tlb_we),
        .exe2_invtlb_asid(exe2_invtlb_asid),
        .exe2_invtlb_op(exe2_invtlb_op),
        .exe2_invtlb_va(exe2_invtlb_va),
        .exe2_invtlb_valid(exe2_invtlb_valid),
        .exe2_alu_op(exe2_alu_op),
        .exe2_tlb_or_csr_we(exe2_tlb_or_csr_we),
        .exe2_inst_tlb_ex(exe2_inst_tlb_ex),
        .exe2_data_tlb_ex(data_tlb_ex),
        //.exe_csr_rdata(exe_csr_rdata),
        .mem_ref_we(mem_ref_we),
        .mem_alu_result(mem_alu_result),
        .mem_dram_re(mem_dram_re),
        .mem_dram_we(mem_dram_we),
        .mem_rd(mem_rd),
        //.mem_br_taken(mem_br_taken),
        //.mem_br_target(mem_br_target),
        .mem_res_from_dram(mem_res_from_dram),
        .mem_dram_wdata(mem_dram_wdata),
        .mem_dram_waddr(mem_dram_waddr),
        .mem_pc(mem_pc),
        .mem_rdram_need_zero_extend(mem_rdram_need_zero_extend),
        .mem_rdram_need_signed_extend(mem_rdram_need_signed_extend),
        .mem_rdram_num(mem_rdram_num),
        .mem_wdram_num(mem_wdram_num),
        .mem_csr_num(mem_csr_num),
        .mem_csr_we(mem_csr_we),
        .mem_is_ertn(mem_is_ertn),
        .mem_is_syscall(mem_is_syscall),
        .mem_res_from_csr(mem_res_from_csr),
        .mem_csr_wmask(mem_csr_wmask),
        .mem_csr_wdata(mem_csr_wdata),
        .mem_ex_adef(mem_ex_adef),
        .mem_ex_brk(mem_ex_brk),
        .mem_ex_ine(mem_ex_ine),
        .mem_ex_ale(mem_ex_ale),
        .mem_has_int(mem_has_int),
        .mem_int_ecode(mem_int_ecode),
        .mem_int_esubcode(mem_int_esubcode),
        .mem_rj(mem_rj),
        .mem_res_of_cnt(mem_res_of_cnt),
        .mem_res_is_rj(mem_res_is_rj),
        .mem_res_from_cnt(mem_res_from_cnt),
        .mem_res_from_tid(mem_res_from_tid),
        .mem_need_data_sram(mem_need_data_sram),
        .mem_ex_ale_h(mem_ex_ale_h),
        .mem_ex_ale_w(mem_ex_ale_w),
        .mem_data_addr(mem_data_addr),
        .mem_need_cancel(mem_need_cancel),
        .mem_inst_tlbrd(mem_inst_tlbrd),
        .mem_inst_tlbsrch(mem_inst_tlbsrch),
        .mem_tlb_we(mem_tlb_we),
        .mem_tlb_fill_en(mem_tlb_fill_en),
        .mem_tlb_wr_en(mem_tlb_wr_en),
        .mem_invtlb_asid(mem_invtlb_asid),
        .mem_invtlb_op(mem_invtlb_op),
        .mem_invtlb_va(mem_invtlb_va),
        .mem_invtlb_valid(mem_invtlb_valid),
        .mem_alu_op(mem_alu_op),
        .mem_tlb_or_csr_we(mem_tlb_or_csr_we),
        .mem_inst_tlb_ex(mem_inst_tlb_ex),
        .mem_data_tlb_ex(mem_data_tlb_ex),
        .mem_inst(mem_inst)
    );
    //assign data_sram_addr=mem_alu_result;

    wire [31:0] mem_alu_ret = (mem_alu_op==5'd22 || mem_alu_op == 5'd23) ?   div_rest : mem_alu_result;
    wire data_tlb_or_csr_we;

    assign mem_dram_rdata=data_sram_rdata;

    wire        exe2_is_cacop;
    wire [4:0]  exe2_cacop_op;
    wire [1:0]  exe2_cacop_code;
    wire        exe2_cacop_is_i;
    wire        exe2_cacop_is_d;
    wire        exe2_cacop_op2;
    wire        mem_is_cacop;
    wire [4:0]  mem_cacop_op;
    wire        mem_cacop_is_i;
    wire        mem_cacop_is_d;

    assign exe2_is_cacop    = (exe2_inst[31:22] == 10'b0000011000);
    assign exe2_cacop_op    = exe2_inst[4:0];
    assign exe2_cacop_code  = exe2_inst[4:3];
    assign exe2_cacop_is_i  = exe2_is_cacop && (exe2_cacop_op[0] == 1'b0);
    assign exe2_cacop_is_d  = exe2_is_cacop && (exe2_cacop_op[0] == 1'b1);
    assign exe2_cacop_op2   = exe2_is_cacop && (exe2_cacop_code == 2'b10);
    assign mem_is_cacop     = (mem_inst[31:22] == 10'b0000011000);
    assign mem_cacop_op     = mem_inst[4:0];
    assign mem_cacop_is_i   = mem_is_cacop && (mem_cacop_op[0] == 1'b0);
    assign mem_cacop_is_d   = mem_is_cacop && (mem_cacop_op[0] == 1'b1);

    assign data_sram_wstrb=(wb_ex===1'b1||exe2_ex_ale===1'b1||wb_is_ertn===1'b1 || data_tlb_ex != 3'b0)?    4'b0000:
                        (exe2_dram_we&&exe2_wdram_num==0)? 4'b1111:
                        (exe2_dram_we&&exe2_wdram_num==1&&data_sram_addr[1:0]==2'b00)?  4'b0001:
                        (exe2_dram_we&&exe2_wdram_num==1&&data_sram_addr[1:0]==2'b01)?4'b0010:
                        (exe2_dram_we&&exe2_wdram_num==1&&data_sram_addr[1:0]==2'b10)? 4'b0100:
                        (exe2_dram_we&&exe2_wdram_num==1&&data_sram_addr[1:0]==2'b11)? 4'b1000:
                        (exe2_dram_we&&exe2_wdram_num==2&&data_sram_addr[1:0]==2'b00)?4'b0011:
                        (exe2_dram_we&&exe2_wdram_num==2&&data_sram_addr[1:0]==2'b01)?4'b0110:
                        (exe2_dram_we&&exe2_wdram_num==2&&data_sram_addr[1:0]==2'b10)?4'b1100:   4'b0000;

    wire normal_data_sram_req;
    wire cacheop_req;
    assign normal_data_sram_req = data_req_valid & exe2_need_data_sram & mem_allow_in &&(wb_ex!=1'b1) & (!(data_tlb_or_csr_we === 1'b1)) &(data_tlb_ex == 3'b0);
    assign cacheop_req = data_req_valid & exe2_is_cacop & mem_allow_in &&(wb_ex!=1'b1) & (!(data_tlb_or_csr_we === 1'b1)) &(data_tlb_ex == 3'b0);
    assign data_sram_req= normal_data_sram_req | cacheop_req;
    assign data_sram_size = exe2_ex_ale_h ? 2'b1 :
                            exe2_ex_ale_w ? 2'b10 :  2'b0;
    assign exe2_addr_shake_ok = (exe2_need_data_sram || exe2_is_cacop) ?  (data_sram_req&&(data_sram_addr_ok===1'b1) || (data_tlb_ex!=3'b0)) :  1'b1;
    assign mem_data_shake_ok = (mem_need_data_sram || mem_is_cacop) ?  (data_sram_data_ok===1'b1) : 1'b1;
    assign data_sram_wr = exe2_dram_we;
    assign mem_need_and_data_ok = mem_need_data_sram && (data_sram_data_ok===1'b1);
   // assign data_sram_en=1'b1;
    //assign data_sram_wdata=mem_dram_wdata;
    assign data_sram_wdata =  exe2_wdram_num==0?  exe2_dram_wdata:
                             exe2_wdram_num==1?   {4{exe2_dram_wdata[7:0]}} :{2{exe2_dram_wdata[15:0]}} ;
    assign data_sram_addr=exe2_alu_result;

    wire [31:0] data_addr;   // 经过TLB转换后的地址
    wire [1:0]  data_mat;
    wire        data_uncached;
    wire data_dmw0_en;
    wire data_dmw1_en;
    wire [2:0]data_tlb_ex;

    assign data_tlb_ex = ((csr_crmd_da && csr_crmd_pg==1'b0)|| data_dmw0_en || data_dmw1_en || (exe2_need_data_sram==1'b0 && exe2_cacop_op2==1'b0)) ? 3'h0 :
                         (tlb_s1_found == 1'b0)                                              ? 3'h1 :
                         (tlb_s1_v == 1'b0 && (exe2_is_ld || exe2_cacop_op2))              ? 3'h2 :
                         (tlb_s1_v == 1'b0 && exe2_is_st)                                     ? 3'h3 :
                         (tlb_s1_plv < csr_crmd_plv)                                         ? 3'h4 :
                         (tlb_s1_d == 1'b0 && exe2_is_st)                                     ? 3'h5 : 3'h0;

    // (debug removed)

    assign data_dmw0_en = csr_crmd_da == 1'b0 && csr_crmd_pg && ((csr_crmd_plv == 2'h3 && csr_dmw0_plv3)||(csr_crmd_plv == 2'h0 && csr_dmw0_plv0)) && data_sram_addr[31:29] == csr_dmw0_vseg;
    assign data_dmw1_en = csr_crmd_da == 1'b0 && csr_crmd_pg && ((csr_crmd_plv == 2'h3 && csr_dmw1_plv3)||(csr_crmd_plv == 2'h0 && csr_dmw1_plv0)) && data_sram_addr[31:29] == csr_dmw1_vseg;
    assign data_addr = (csr_crmd_da && csr_crmd_pg==1'b0) ?  data_sram_addr :
                        data_dmw0_en                       ?  {csr_dmw0_pseg,data_sram_addr[28:0]} :
                        data_dmw1_en                       ?  {csr_dmw1_pseg,data_sram_addr[28:0]} :  {tlb_s1_ppn[19:0],data_sram_addr[11:0]};
    assign data_mat  = (csr_crmd_da && csr_crmd_pg==1'b0) ?  csr_crmd_datm :
                        data_dmw0_en                       ?  csr_dmw0_mat :
                        data_dmw1_en                       ?  csr_dmw1_mat : tlb_s1_mat;
    assign data_uncached = ~data_mat[0];

    assign data_tlb_or_csr_we = mem_tlb_or_csr_we | wb_tlb_or_csr_we;


    wire  wb_rf_we;
    wire [31:0] wb_alu_result;
    wire [4:0] wb_rd;
    //wire [31:0] wb_br_target;
    //wire wb_br_taken;
    wire [31:0]wb_dram_rdata;
    wire wb_res_from_dram;
    wire [31:0] wb_dram_wdata;
    wire [31:0] wb_dram_waddr;
    wire wb_dram_we;
    wire [31:0] wb_pc;
    wire [1:0]wb_wdram_num;
    wire [1:0]wb_rdram_num;
    wire wb_rdram_need_zero_extend;
    wire wb_rdram_need_signed_extend;
    wire [31:0] wb_data_addr;
    wire [13:0] wb_csr_num;
    wire wb_csr_we;
    wire wb_is_ertn;
    wire wb_is_syscall;
    wire wb_res_from_csr;
    wire [31:0] csr_rvalue;
    wire [31:0] wb_csr_wmask;
    wire [31:0] wb_csr_wdata;
    wire wb_ex_adef;
    wire wb_ex_ale;
    wire wb_ex_brk;
    wire wb_ex_ine;
    wire wb_has_int;
    wire [5:0] wb_int_ecode;
    wire [7:0] wb_int_esubcode;
    wire wb_res_from_tid;
    wire wb_need_cancel;
    wire wb_inst_tlbrd;
    wire [4:0] wb_rj;
    wire [31:0] wb_res_of_cnt;
    wire wb_inst_tlbsrch;
    wire wb_tlb_we;
    wire wb_tlb_fill_en;
    wire wb_tlb_wr_en;
    wire wb_invtlb_valid;
    wire [4:0]wb_invtlb_op;
    wire [9:0]wb_invtlb_asid;
    wire [18:0]wb_invtlb_va;
    wire wb_tlb_or_csr_we;
    wire [1:0] wb_inst_tlb_ex;
    wire [2:0] wb_data_tlb_ex;


   // wire [31:0] wb_csr_rdata;

    Wb_reg wb_reg(
        .clk(clk),
        .rst(rst),
        .wb_ex(wb_ex),
        .mem_ready_go(mem_ready_go),
        .mem_alu_result(mem_alu_ret),
        .mem_ref_we(mem_ref_we),
        .mem_rd(mem_rd),
       // .mem_br_taken(mem_br_taken),
        //.mem_br_target(mem_br_target),
        .mem_dram_rdata(mem_dram_rdata),
        .mem_res_from_dram(mem_res_from_dram),
        .mem_dram_wdata(mem_dram_wdata),
        .mem_dram_waddr(mem_dram_waddr),
        .mem_dram_we(mem_dram_we),
        .mem_pc(mem_pc),
        .mem_wdram_num(mem_wdram_num),
        .mem_rdram_num(mem_rdram_num),
        .mem_rdram_need_zero_extend(mem_rdram_need_zero_extend),
        .mem_rdram_need_signed_extend(mem_rdram_need_signed_extend),
        .mem_data_addr(mem_data_addr),
        .mem_csr_num(mem_csr_num),
        .mem_csr_we(mem_csr_we),
        .mem_is_ertn(mem_is_ertn),
        .mem_is_syscall(mem_is_syscall),
        .mem_res_from_csr(mem_res_from_csr),
        .mem_csr_wmask(mem_csr_wmask),
        .mem_csr_wdata(mem_csr_wdata),
        .mem_ex_adef(mem_ex_adef),
        .mem_ex_brk(mem_ex_brk),
        .mem_ex_ine(mem_ex_ine),
        .mem_ex_ale(mem_ex_ale),
        .mem_has_int(mem_has_int),
        .mem_int_ecode(mem_int_ecode),
        .mem_int_esubcode(mem_int_esubcode),
        .mem_rj(mem_rj),
        .mem_res_of_cnt(mem_res_of_cnt),
        .mem_res_is_rj(mem_res_is_rj),
        .mem_res_from_cnt(mem_res_from_cnt),
        .mem_res_from_tid(mem_res_from_tid),
        .mem_need_cancel(mem_need_cancel),
        .mem_inst_tlbrd(mem_inst_tlbrd),
        .mem_inst_tlbsrch(mem_inst_tlbsrch),
        .mem_tlb_we(mem_tlb_we),
        .mem_tlb_wr_en(mem_tlb_wr_en),
        .mem_tlb_fill_en(mem_tlb_fill_en),
        .mem_invtlb_asid(mem_invtlb_asid),
        .mem_invtlb_op(mem_invtlb_op),
        .mem_invtlb_va(mem_invtlb_va),
        .mem_invtlb_valid(mem_invtlb_valid),
        .mem_tlb_or_csr_we(mem_tlb_or_csr_we),
        .mem_inst_tlb_ex(mem_inst_tlb_ex),
        .mem_data_tlb_ex(mem_data_tlb_ex),
        .mem_inst(mem_inst),
        //.mem_csr_rdata(mem_csr_rdata),
        .wb_rf_we(wb_rf_we),
        .wb_alu_result(wb_alu_result),
        .wb_rd(wb_rd),
        //.wb_br_taken(wb_br_taken),
        //.wb_br_target(wb_br_target),
        .wb_dram_rdata(wb_dram_rdata),
        .wb_res_from_dram(wb_res_from_dram),
        .wb_dram_waddr(wb_dram_waddr),
        .wb_dram_wdata(wb_dram_wdata),
        .wb_dram_we(wb_dram_we),
        .wb_wdram_num(wb_wdram_num),
        .wb_pc(wb_pc),
        .wb_rdram_num(wb_rdram_num),
        .wb_rdram_need_signed_extend(wb_rdram_need_signed_extend),
        .wb_rdram_need_zero_extend(wb_rdram_need_zero_extend),
        .wb_data_addr(wb_data_addr),
        .wb_csr_num(wb_csr_num),
        .wb_csr_we(wb_csr_we),
        .wb_is_ertn(wb_is_ertn),
        .wb_is_syscall(wb_is_syscall),
        .wb_res_from_csr(wb_res_from_csr),
        .wb_csr_wmask(wb_csr_wmask),
        .wb_csr_wdata(wb_csr_wdata),
        .wb_ex_adef(wb_ex_adef),
        .wb_ex_brk(wb_ex_brk),
        .wb_ex_ine(wb_ex_ine),
        .wb_ex_ale(wb_ex_ale),
        .wb_has_int(wb_has_int),
        .wb_int_ecode(wb_int_ecode),
        .wb_int_esubcode(wb_int_esubcode),
        .wb_rj(wb_rj),
        .wb_res_of_cnt(wb_res_of_cnt),
        .wb_res_is_rj(wb_res_is_rj),
        .wb_res_from_cnt(wb_res_from_cnt),
        .wb_res_from_tid(wb_res_from_tid),
        .wb_need_cancel(wb_need_cancel),
        .wb_inst_tlbrd(wb_inst_tlbrd),
        .wb_inst_tlbsrch(wb_inst_tlbsrch),
        .wb_tlb_we(wb_tlb_we),
        .wb_tlb_wr_en(wb_tlb_wr_en),
        .wb_tlb_fill_en(wb_tlb_fill_en),
        .wb_invtlb_asid(wb_invtlb_asid),
        .wb_invtlb_op(wb_invtlb_op),
        .wb_invtlb_va(wb_invtlb_va),
        .wb_invtlb_valid(wb_invtlb_valid),
        .wb_tlb_or_csr_we(wb_tlb_or_csr_we),
        .wb_inst_tlb_ex(wb_inst_tlb_ex),
        .wb_data_tlb_ex(wb_data_tlb_ex),
        .wb_inst(wb_inst)

    );



    wire [31:0] mem_to_rf_data;
    wire rf_we;
    assign rf_we = (wb_ex_ale===1'b1) ? 1'b0  :  wb_rf_we & !(wb_ex===1'b1);
    assign mem_to_rf_data = wb_rdram_num==0 ?   wb_dram_rdata :
                            (wb_rdram_num==1&&wb_data_addr[1:0]==2'b00&&wb_rdram_need_signed_extend) ?  {{16{wb_dram_rdata[15]}},wb_dram_rdata[15:0]}   :
                            (wb_rdram_num==1&&wb_data_addr[1:0]==2'b00&&wb_rdram_need_zero_extend) ?  {{16{1'b0}},wb_dram_rdata[15:0]}   :
                            (wb_rdram_num==1&&wb_data_addr[1:0]==2'b01&&wb_rdram_need_signed_extend) ?  {{16{wb_dram_rdata[23]}},wb_dram_rdata[23:8]}   :
                            (wb_rdram_num==1&&wb_data_addr[1:0]==2'b01&&wb_rdram_need_zero_extend) ?  {{16{1'b0}},wb_dram_rdata[23:8]}   :
                            (wb_rdram_num==1&&wb_data_addr[1:0]==2'b10&&wb_rdram_need_signed_extend) ?  {{16{wb_dram_rdata[31]}},wb_dram_rdata[31:16]}   :
                            (wb_rdram_num==1&&wb_data_addr[1:0]==2'b10&&wb_rdram_need_zero_extend) ?  {{16{1'b0}},wb_dram_rdata[31:16]}   :
                            (wb_rdram_num==2&&wb_data_addr[1:0]==2'b00&&wb_rdram_need_signed_extend) ?  {{24{wb_dram_rdata[7]}},wb_dram_rdata[7:0]}   :
                            (wb_rdram_num==2&&wb_data_addr[1:0]==2'b00&&wb_rdram_need_zero_extend) ?  {{24{1'b0}},wb_dram_rdata[7:0]}   :
                            (wb_rdram_num==2&&wb_data_addr[1:0]==2'b01&&wb_rdram_need_signed_extend) ?  {{24{wb_dram_rdata[15]}},wb_dram_rdata[15:8]}   :
                            (wb_rdram_num==2&&wb_data_addr[1:0]==2'b01&&wb_rdram_need_zero_extend) ?  {{24{1'b0}},wb_dram_rdata[15:8]}   :
                            (wb_rdram_num==2&&wb_data_addr[1:0]==2'b10&&wb_rdram_need_signed_extend) ?  {{24{wb_dram_rdata[23]}},wb_dram_rdata[23:16]}   :
                            (wb_rdram_num==2&&wb_data_addr[1:0]==2'b10&&wb_rdram_need_zero_extend) ?  {{24{1'b0}},wb_dram_rdata[23:16]}   :
                            (wb_rdram_num==2&&wb_data_addr[1:0]==2'b11&&wb_rdram_need_signed_extend) ?  {{24{wb_dram_rdata[31]}},wb_dram_rdata[31:24]}   :
                            (wb_rdram_num==2&&wb_data_addr[1:0]==2'b11&&wb_rdram_need_zero_extend) ?  {{24{1'b0}},wb_dram_rdata[31:24]}   : 32'b0;

    assign rf_raddr1 = id_rj;
    assign rf_raddr2 = id_src2_is_rd? id_rd: id_rk;
    assign rf_wdata = wb_res_from_dram? mem_to_rf_data:
                      (wb_res_from_csr|wb_res_from_tid)? csr_rvalue :
                      wb_res_from_cnt?  wb_res_of_cnt:wb_alu_result;

    wire [4:0]rf_waddr;
    assign rf_waddr = wb_res_is_rj? wb_rj : wb_rd;
`ifdef DIFFTEST_EN
    wire [31:0] gp_regs_diff [31:0];
    wire [831:0] csr_all_diff;
`endif
    regfile rf(
        .raddr1(rf_raddr1),
        .raddr2(rf_raddr2),
        .rdata1(rf_rdata1),
        .rdata2(rf_rdata2),
        .clk(clk),
        .waddr(rf_waddr),
        .wdata(rf_wdata),
        .we(rf_we)
`ifdef DIFFTEST_EN
        ,
        .rf_regs_diff(gp_regs_diff)
`endif
    );
    
    assign id_src1=rf_rdata1;
    assign id_src2=rf_rdata2;
    assign debug0_wb_pc = wb_pc;
    assign debug0_wb_rf_wen ={4{rf_we}} ;
    assign debug0_wb_rf_wnum=wb_rd;
    assign debug0_wb_rf_wdata=rf_wdata;


    //assign if_allow_in = inst_sram_data_ok==1'b0;
    assign exe1_ready_go=   (wb_ex===1'b1)?                                            1'b0:
                            (exe1_alu_op == 5'd20 || exe1_alu_op == 5'd21 || exe1_alu_op == 5'd22 || exe1_alu_op == 5'd23)?   div_done :
                            1'b1;
    assign exe2_ready_go=   (wb_ex===1'b1)?                                            1'b0:
                            (EXE2_ready_go == 1'b1) ?                                  1'b1 :
                            (exe2_need_data_sram || exe2_is_cacop) ? ((data_sram_addr_ok===1'b1 && data_sram_req)||(data_tlb_ex!=3'b0)) : 1'b1;
    assign mem_ready_go=     (wb_ex===1'b1)?                                                 1'b0:
                            (mem_need_data_sram || mem_is_cacop) ?  (data_sram_data_ok===1'b1||mem_data_tlb_ex != 3'b0) : 1'b1;
    assign pre_if_ready_go =(inst_sram_addr_ok && inst_sram_req)||(inst_tlb_ex != 2'b0);
    //assign if_ready_go =1'b1;
    //assign id_ready_go =1'b1;
    //assign wb_ready_go=1'b1;
    assign if_ready_go = rst? 1'b1:
                         (IF_ready_go == 1'b1) ?     1'b1:
                        (if_pc!=32'h1bfffffc&&real_inst_data_ok==1'b0)? 1'b0 :
                        (exe1_ref_we&&exe1_rd!=0&&((id_src1_from_ref&&(rf_raddr1==exe1_rd))||(id_src2_from_ref&&(rf_raddr2==exe1_rd))))? 1'b0 :
                        (exe2_ref_we&&exe2_rd!=0&&((id_src1_from_ref&&(rf_raddr1==exe2_rd))||(id_src2_from_ref&&(rf_raddr2==exe2_rd))))? 1'b0 :
                        (mem_ref_we&&mem_rd!=0&&((id_src1_from_ref&&(rf_raddr1==mem_rd))||(id_src2_from_ref&&(rf_raddr2==mem_rd))))?  1'b0:
                        (wb_rf_we&&wb_rd!=0&&((id_src1_from_ref&&(rf_raddr1==wb_rd))||(id_src2_from_ref&&(rf_raddr2==wb_rd))))?  1'b0  : 1'b1;
                        // (exe_csr_we&&(exe_csr_num==14'h4||exe_csr_num==14'd5||exe_csr_num==14'b0)) ?       1'b0:
                        // (mem_csr_we&&(mem_csr_num==14'h4||mem_csr_num==14'd5||mem_csr_num==14'b0)) ?       1'b0:
                        // (wb_csr_we&&(wb_csr_num==14'h4||wb_csr_num==14'd5||wb_csr_num==14'b0)) ?       1'b0:   1'b1;
    assign id_ready_go = rst? 1'b1:
                        (wb_ex===1'b1)? 1'b0:
                        (exe1_div_is_doing)? 1'b0 :
                        (exe1_ref_we&&exe1_rd!=0&&((id_src1_from_ref&&(rf_raddr1==exe1_rd))||(id_src2_from_ref&&(rf_raddr2==exe1_rd))))? 1'b0 :
                        (exe2_ref_we&&exe2_rd!=0&&((id_src1_from_ref&&(rf_raddr1==exe2_rd))||(id_src2_from_ref&&(rf_raddr2==exe2_rd))))? 1'b0 :
                        (mem_ref_we&&mem_rd!=0&&((id_src1_from_ref&&(rf_raddr1==mem_rd))||(id_src2_from_ref&&(rf_raddr2==mem_rd))))?  1'b0:
                        (wb_rf_we&&wb_rd!=0&&((id_src1_from_ref&&(rf_raddr1==wb_rd))||(id_src2_from_ref&&(rf_raddr2==wb_rd))))?  1'b0  :
                        (ID_ready_go == 1'b1) ?      1'b1 : 1'b1;
                        // (exe_csr_we&&(exe_csr_num==14'h4||exe_csr_num==14'd5||exe_csr_num==14'b0)) ?       1'b0:
                        // (mem_csr_we&&(mem_csr_num==14'h4||mem_csr_num==14'd5||mem_csr_num==14'b0)) ?       1'b0:
                        // (wb_csr_we&&(wb_csr_num==14'h4||wb_csr_num==14'd5||wb_csr_num==14'b0)) ?       1'b0:   1'b1;
    assign wb_ready_go =rst? 1'b1:
                        (wb_ex===1'b1)? 1'b0:
                        //(wb_is_ertn===1'b1) ? 1'b1:
                        (inst_sram_data_ok==1'b0)? 1'b0 :
                        (exe1_ref_we&&exe1_rd!=0&&((id_src1_from_ref&&(rf_raddr1==exe1_rd))||(id_src2_from_ref&&(rf_raddr2==exe1_rd))))? 1'b0 :
                        (exe2_ref_we&&exe2_rd!=0&&((id_src1_from_ref&&(rf_raddr1==exe2_rd))||(id_src2_from_ref&&(rf_raddr2==exe2_rd))))? 1'b0 :
                        (mem_ref_we&&mem_rd!=0&&((id_src1_from_ref&&(rf_raddr1==mem_rd))||(id_src2_from_ref&&(rf_raddr2==mem_rd))))?  1'b0:
                        (wb_rf_we&&wb_rd!=0&&((id_src1_from_ref&&(rf_raddr1==wb_rd))||(id_src2_from_ref&&(rf_raddr2==wb_rd))))?  1'b0  : 1'b1;
                        // (exe_csr_we&&(exe_csr_num==14'h4||exe_csr_num==14'd5||exe_csr_num==14'b0)) ?       1'b0:
                        // (mem_csr_we&&(mem_csr_num==14'h4||mem_csr_num==14'd5||mem_csr_num==14'b0)) ?       1'b0:
                        // (wb_csr_we&&(wb_csr_num==14'h4||wb_csr_num==14'd5||wb_csr_num==14'b0)) ?       1'b0:   1'b1;
    assign pipline_is_not_stalled =rst? 1'b1:
                       // (wb_ex===1'b1)? 1'b1:
                        (exe1_ref_we&&exe1_rd!=0&&((id_src1_from_ref&&(rf_raddr1==exe1_rd))||(id_src2_from_ref&&(rf_raddr2==exe1_rd))))? 1'b0 :
                        (exe2_ref_we&&exe2_rd!=0&&((id_src1_from_ref&&(rf_raddr1==exe2_rd))||(id_src2_from_ref&&(rf_raddr2==exe2_rd))))? 1'b0 :
                        (mem_ref_we&&mem_rd!=0&&((id_src1_from_ref&&(rf_raddr1==mem_rd))||(id_src2_from_ref&&(rf_raddr2==mem_rd))))?  1'b0:
                        (wb_rf_we&&wb_rd!=0&&((id_src1_from_ref&&(rf_raddr1==wb_rd))||(id_src2_from_ref&&(rf_raddr2==wb_rd))))?  1'b0  : 1'b1;
                        // (exe_csr_we&&(exe_csr_num==14'h4||exe_csr_num==14'd5||exe_csr_num==14'b0)) ?       1'b0:
                        // (mem_csr_we&&(mem_csr_num==14'h4||mem_csr_num==14'd5||mem_csr_num==14'b0)) ?       1'b0:
                        // (wb_csr_we&&(wb_csr_num==14'h4||wb_csr_num==14'd5||wb_csr_num==14'b0)) ?       1'b0:   1'b1;
    assign wb_allow_in = 1'b1;
    assign mem_allow_in = wb_allow_in && !(mem_ready_go===1'b0);
    assign exe2_allow_in = mem_allow_in && !(exe2_ready_go===1'b0);
    assign exe1_allow_in = exe2_allow_in && !(exe1_ready_go===1'b0);
    assign id_allow_in = exe1_allow_in && !(id_ready_go===1'b0) && !exe1_dropped && !btb_mispredict;

    if_allow_in_state u_if_allow_in_state(
        .clk(clk),
        .rst(rst),
        .pre_if_ready_go(pre_if_ready_go),
        .if_ready_go(if_ready_go),
        .id_allow_in(id_allow_in),
        .redirect(wb_ex || wb_is_ertn),
        .data_ok(real_inst_data_ok),
        .if_allow_in(if_allow_in)
    );

    wire wb_ex;//是否是异常 (driven by trap_unit.trap_ex_valid via .trap_ex_valid(wb_ex))
    wire [5:0]wb_ecode;
    wire [7:0]wb_esubcode;//异常类型的编号
    wire trap_flush;
    wire trap_ertn;

    // trap_unit.v 实例化 - WB阶段异常检测和处理
    trap_unit u_trap_unit(
        .clk(clk),
        .rst(rst),
        // Re-check IE at WB: interrupt detected in ID may have IE cleared by now
        .wb_has_int(wb_has_int && csr_crmd_ie),
        .wb_int_ecode(wb_int_ecode),
        .wb_int_esubcode(wb_int_esubcode),
        .wb_ex_adef(wb_ex_adef),
        .wb_ex_brk(wb_ex_brk),
        .wb_ex_ine(wb_ex_ine),
        .wb_ex_ale(wb_ex_ale),
        .wb_is_syscall(wb_is_syscall),
        .wb_is_ertn(wb_is_ertn),
        .wb_inst_tlb_ex(wb_inst_tlb_ex),
        .wb_data_tlb_ex(wb_data_tlb_ex),
        .wb_need_cancel(wb_need_cancel),
        .trap_ex_valid(wb_ex),
        .trap_ecode(wb_ecode),
        .trap_esubcode(wb_esubcode),
        .trap_flush(trap_flush),
        .trap_ertn(trap_ertn)
    );

    // Wb_stage 现在只作为信号传递模块，异常检测由 trap_unit 完成
    // 如果需要，可以后续完全移除 Wb_stage
    // Wb_stage wb_stage(
    //     .wb_is_syscall(wb_is_syscall),
    //     .wb_ecode(wb_ecode),
    //     .wb_esubcode(wb_esubcode),
    //     .wb_ex(wb_ex),
    //     .wb_is_ertn(wb_is_ertn),
    //     .wb_ex_adef(wb_ex_adef),
    //     .wb_ex_ale(wb_ex_ale),
    //     .wb_ex_brk(wb_ex_brk),
    //     .wb_ex_ine(wb_ex_ine),
    //     .wb_need_cancel(wb_need_cancel),
    //     .wb_has_int(wb_has_int),
    //     .wb_inst_tlb_ex(wb_inst_tlb_ex),
    //     .wb_data_tlb_ex(wb_data_tlb_ex)
    // );

    wire [13:0]csr_num;

    wire [7:0]hw_int_in;

    assign hw_int_in = 8'b0 ;

    wire [31:0] coueid_in=32'b0;
    wire ipi_int_in=1'b0;
    wire [12:0] csr_estat_is;
    wire [12:0] csr_ecfg_lie;
    wire csr_crmd_ie;
    wire [31:0] wb_ex_ale_addr;
    wire csr_ex;
    wire [3:0] csr_tlbidx_index;
    wire csr_tlbidx_index_invalid;
    wire csr_tlbidx_index_we;
    wire [3:0]csr_tlbidx_index_wvalue;
    wire csr_tlbehi_we;
    wire [18:0]csr_tlbehi_wvalue;

    wire csr_tlbelo0_v_we;
    wire csr_tlbelo0_v_wvalue;
    wire csr_tlbelo0_d_we;
    wire csr_tlbelo0_d_wvalue;
    wire csr_tlbelo0_plv_we;
    wire [1:0]csr_tlbelo0_plv_wvalue;
    wire csr_tlbelo0_mat_we;
    wire [1:0]csr_tlbelo0_mat_wvalue;
    wire csr_tlbelo0_g_we;
    wire csr_tlbelo0_g_wvalue;
    wire csr_tlbelo0_ppn_we;
    wire [19:0]csr_tlbelo0_ppn_wvalue;

    wire csr_tlbelo1_v_we;
    wire csr_tlbelo1_v_wvalue;
    wire csr_tlbelo1_d_we;
    wire csr_tlbelo1_d_wvalue;
    wire csr_tlbelo1_plv_we;
    wire [1:0]csr_tlbelo1_plv_wvalue;
    wire csr_tlbelo1_mat_we;
    wire [1:0]csr_tlbelo1_mat_wvalue;
    wire csr_tlbelo1_g_we;
    wire csr_tlbelo1_g_wvalue;
    wire csr_tlbelo1_ppn_we;
    wire [19:0]csr_tlbelo1_ppn_wvalue;

    wire csr_tlbidx_ne_we;
    wire csr_tlbidx_ne_wvalue;
    wire csr_tlbidx_ps_we;
    wire [5:0]csr_tlbidx_ps_wvalue;

    wire csr_asid_asid_we;
    wire [9:0]csr_asid_asid_wvalue;

    wire [9:0] csr_asid_asid;
    wire [5:0] csr_estat_ecode;
    wire csr_tlbidx_ne;
    wire [5:0] csr_tlbidx_ps;
    wire csr_tlbelo0_d;
    wire csr_tlbelo0_g;
    wire csr_tlbelo0_v;
    wire [1:0]csr_tlbelo0_mat;
    wire [19:0] csr_tlbelo0_ppn;
    wire [1:0] csr_tlbelo0_plv;
    wire csr_tlbelo1_d;
    wire csr_tlbelo1_g;
    wire csr_tlbelo1_v;
    wire [1:0] csr_tlbelo1_mat;
    wire [19:0] csr_tlbelo1_ppn;
    wire [1:0] csr_tlbelo1_plv;
    wire [18:0] csr_tlbehi;
    wire csr_dmw0_plv0;
    wire csr_dmw0_plv3;
    wire [1:0]csr_dmw0_mat;
    wire [2:0]csr_dmw0_pseg;
    wire [2:0] csr_dmw0_vseg;
    wire csr_dmw1_plv0;
    wire csr_dmw1_plv3;
    wire [1:0]csr_dmw1_mat;
    wire [2:0]csr_dmw1_pseg;
    wire [2:0] csr_dmw1_vseg;
    wire csr_crmd_da;
    wire csr_crmd_pg;
    wire [1:0] csr_crmd_datf;
    wire [1:0] csr_crmd_datm;
    wire [31:0] csr_dmw0;
    wire [31:0] csr_dmw1;
    wire [1:0] csr_crmd_plv;
    wire csr_inst_tlb_refill;
    wire csr_data_tlb_refill;

    assign csr_inst_tlb_refill = wb_inst_tlb_ex == 2'b1;
    assign csr_data_tlb_refill = wb_data_tlb_ex == 3'b1;

    assign csr_dmw0 ={csr_dmw0_vseg,1'b0,csr_dmw0_pseg,19'b0,csr_dmw0_mat,csr_dmw0_plv3,2'b0,csr_dmw0_plv0} ;
    assign csr_dmw1 ={csr_dmw1_vseg,1'b0,csr_dmw1_pseg,19'b0,csr_dmw1_mat,csr_dmw1_plv3,2'b0,csr_dmw1_plv0} ;

    assign csr_ex = (wb_ex===1'b1) && wb_is_ertn==1'b0 ;

    assign wb_ex_ale_addr=wb_data_addr;
    assign csr_num = (wb_ex&&wb_is_ertn==1'b0) ?           14'hc :
                    wb_res_from_tid?   14'h40:  wb_csr_num;  //中断的话，要去读中断程序入口地址，csr_rvalue即为入口地址

    wire [25:0] csr_tlbrentry;

    CSRREG csr(
        .clk(clk),//
        .rst(rst),//
        .timer_advance(!exe1_dropped),
        .csr_num(csr_num),//
        .csr_we(wb_csr_we),//
        .csr_wmask(wb_csr_wmask),//
        .wb_ertn_flush(wb_is_ertn),//
        .wb_ex(csr_ex),//
        .wb_ecode(wb_ecode),//
        .wb_esubcode(wb_esubcode),//
        .hw_int_in(hw_int_in),
        .coreid_in(coreid_in),
        .ipi_int_in(ipi_int_in),
        .csr_rvalue(csr_rvalue),//
        .csr_wvalue(wb_csr_wdata),//
        .wb_pc(wb_pc),//
        .csr_era_pc(csr_era_pc),
        .wb_ex_ale(wb_ex_ale),
        .wb_ex_ale_addr(wb_ex_ale_addr),
        .csr_estat_is(csr_estat_is),
        .csr_ecfg_lie(csr_ecfg_lie),
        .csr_crmd_ie(csr_crmd_ie),
        .csr_timer_64(csr_timer_64),
        .csr_tid_tid(csr_tid_tid),
        .csr_estat_ecode(csr_estat_ecode),
        .csr_tlbidx_ne(csr_tlbidx_ne),
        .csr_tlbidx_ps(csr_tlbidx_ps),
        .wb_inst_tlb_ex(wb_inst_tlb_ex),
        .wb_data_tlb_ex(wb_data_tlb_ex),
        .wb_data_addr(wb_data_addr),

        .csr_tlbelo0_d(csr_tlbelo0_d),
        .csr_tlbelo0_g(csr_tlbelo0_g),
        .csr_tlbelo0_mat(csr_tlbelo0_mat),
        .csr_tlbelo0_plv(csr_tlbelo0_plv),
        .csr_tlbelo0_ppn(csr_tlbelo0_ppn),
        .csr_tlbelo0_v(csr_tlbelo0_v),
        .csr_tlbelo1_d(csr_tlbelo1_d),
        .csr_tlbelo1_g(csr_tlbelo1_g),
        .csr_tlbelo1_mat(csr_tlbelo1_mat),
        .csr_tlbelo1_plv(csr_tlbelo1_plv),
        .csr_tlbelo1_ppn(csr_tlbelo1_ppn),
        .csr_tlbelo1_v(csr_tlbelo1_v),


        .csr_tlbidx_index(csr_tlbidx_index),                           //   output
        .csr_tlbidx_index_invalid(csr_tlbidx_index_invalid),             //   output
        .csr_tlbidx_index_we(csr_tlbidx_index_we),                     //   input
        .csr_tlbidx_index_wvalue(csr_tlbidx_index_wvalue),             //   input

        .csr_tlbehi_we(csr_tlbehi_we),                                 //   input
        .csr_tlbehi_wvalue(csr_tlbehi_wvalue),                         //   input
        .csr_tlbidx_ps_we(csr_tlbidx_ps_we),
        .csr_tlbidx_ps_wvalue(csr_tlbidx_ps_wvalue),

        .csr_tlbelo0_d_we(csr_tlbelo0_d_we),
        .csr_tlbelo0_d_wvalue(csr_tlbelo0_d_wvalue),

        .csr_tlbelo0_g_we(csr_tlbelo0_g_we),
        .csr_tlbelo0_g_wvalue(csr_tlbelo0_g_wvalue),

        .csr_tlbelo0_v_we(csr_tlbelo0_v_we),
        .csr_tlbelo0_v_wvalue(csr_tlbelo0_v_wvalue),

        .csr_tlbelo0_plv_we(csr_tlbelo0_plv_we),
        .csr_tlbelo0_plv_wvalue(csr_tlbelo0_plv_wvalue),

        .csr_tlbelo0_mat_we(csr_tlbelo0_mat_we),
        .csr_tlbelo0_mat_wvalue(csr_tlbelo0_mat_wvalue),

        .csr_tlbelo0_ppn_we(csr_tlbelo0_ppn_we),
        .csr_tlbelo0_ppn_wvalue(csr_tlbelo0_ppn_wvalue),


        .csr_tlbelo1_d_we(csr_tlbelo1_d_we),
        .csr_tlbelo1_d_wvalue(csr_tlbelo1_d_wvalue),

        .csr_tlbelo1_g_we(csr_tlbelo1_g_we),
        .csr_tlbelo1_g_wvalue(csr_tlbelo1_g_wvalue),

        .csr_tlbelo1_v_we(csr_tlbelo1_v_we),
        .csr_tlbelo1_v_wvalue(csr_tlbelo1_v_wvalue),

        .csr_tlbelo1_plv_we(csr_tlbelo1_plv_we),
        .csr_tlbelo1_plv_wvalue(csr_tlbelo1_plv_wvalue),

        .csr_tlbelo1_mat_we(csr_tlbelo1_mat_we),
        .csr_tlbelo1_mat_wvalue(csr_tlbelo1_mat_wvalue),

        .csr_tlbelo1_ppn_we(csr_tlbelo1_ppn_we),
        .csr_tlbelo1_ppn_wvalue(csr_tlbelo1_ppn_wvalue),

        .csr_tlbidx_ne_we(csr_tlbidx_ne_we),
        .csr_tlbidx_ne_wvalue(csr_tlbidx_ne_wvalue),

        .csr_asid_asid_we(csr_asid_asid_we),
        .csr_asid_asid_wvalue(csr_asid_asid_wvalue),

        .csr_asid_asid(csr_asid_asid),
        .csr_tlbehi(csr_tlbehi),

        .csr_dmw0_plv0(csr_dmw0_plv0),
        .csr_dmw0_plv3(csr_dmw0_plv3),
        .csr_dmw0_mat(csr_dmw0_mat),
        .csr_dmw0_pseg(csr_dmw0_pseg),
        .csr_dmw0_vseg(csr_dmw0_vseg),
        .csr_dmw1_plv0(csr_dmw1_plv0),
        .csr_dmw1_plv3(csr_dmw1_plv3),
        .csr_dmw1_mat(csr_dmw1_mat),
        .csr_dmw1_pseg(csr_dmw1_pseg),
        .csr_dmw1_vseg(csr_dmw1_vseg),
        .csr_crmd_da(csr_crmd_da),
        .csr_crmd_pg(csr_crmd_pg),
        .csr_crmd_datf(csr_crmd_datf),
        .csr_crmd_datm(csr_crmd_datm),
        .csr_crmd_plv(csr_crmd_plv),
        .csr_inst_tlb_refill(csr_inst_tlb_refill),
        .csr_data_tlb_refill(csr_data_tlb_refill),
        .csr_tlbrentry(csr_tlbrentry)
`ifdef DIFFTEST_EN
        ,
        .csr_all_diff(csr_all_diff)
`endif
    );

    Inst_ram_state inst_ram_state(
        .clk(clk),
        .rst(rst),
        .req(inst_sram_req),
        .data_ok(real_inst_data_ok),
        .addr_ok(inst_sram_addr_ok),
        .flush(wb_ex || wb_is_ertn),
        .inst_req_valid(inst_req_valid)
    );

    wire Inst_sram_req;
    assign Inst_sram_req =if_allow_in & inst_req_valid & pc_inst_en & (~pipline_is_not_stalled===1'b0);
    If_to_id_need_cancel if_to_id_need_cancel(
        .clk(clk),
        .rst(rst),
        .wb_ex(wb_ex),
        .pipline_is_not_stalled(pipline_is_not_stalled),
        .inst_sram_req(Inst_sram_req),
        .inst_sram_data_ok(inst_sram_data_ok),
        .inst_sram_addr_ok(inst_sram_addr_ok),
        .if_ready_go(if_ready_go),
        .id_allow_in(id_allow_in),
        .id_br_taken(id_br_taken_safe),
        .id_is_ertn(id_is_ertn),
        .pre_if_ready_go(pre_if_ready_go),
        .if_allow_in(if_allow_in),
        .id_need_cancel(id_need_cancel_raw)     // raw output from state machine
    );

    wire [1:0] id_need_cancel;
    assign id_need_cancel = ((id_br_taken_safe && !btb_hit_d1) || br_need_cancel) ? 2'b10 : id_need_cancel_raw;

    Data_ram_state data_ram_state(
        .clk(clk),
        .rst(rst),
        .req(data_sram_req),
        .data_ok(data_sram_data_ok),
        .addr_ok(data_sram_addr_ok),
        .data_req_valid(data_req_valid)          //表示�???1个请求已经发出，不能再发请求
    );

    id_next_inst_cancel id_next_inst_cancel(
        .clk(clk),
        .rst(rst),
        .id_br_taken(id_br_taken_safe),
        .id_is_ertn(id_is_ertn),
        .id_allow_in(id_allow_in),
        .pre_if_ready_go(pre_if_ready_go),
        .if_allow_in(if_allow_in),
        .id_next_inst_cancel(id_inst_cancel)
    );

    IF_readygo_state If_readygo_state(
        .rst(rst),
        .clk(clk),
        .id_allow_in(id_allow_in),
        .if_ready_go(if_ready_go),
        .IF_ready_go(IF_ready_go)
    );

    EXE2_readygo_state Exe2_readygo_state(
        .rst(rst),
        .clk(clk),
        .mem_allow_in(mem_allow_in),
        .exe2_ready_go(exe2_ready_go),
        .EXE2_ready_go(EXE2_ready_go)
    );

    ID_readygo_state Id_readygo_state(
        .rst(rst),
        .clk(clk),
        .id_ready_go(id_ready_go),
        .exe_allow_in(exe1_allow_in),
        .ID_ready_go(ID_ready_go)
    );

    wire        icache_mem_req;
    wire        icache_mem_wr;
    wire [1:0]  icache_mem_size;
    wire [3:0]  icache_mem_wstrb;
    wire [31:0] icache_mem_addr;
    wire [31:0] icache_mem_wdata;
    wire        icache_mem_addr_ok;
    wire        icache_mem_data_ok;
    wire [31:0] icache_mem_rdata;

    wire        dcache_mem_req;
    wire        dcache_mem_wr;
    wire [1:0]  dcache_mem_size;
    wire [3:0]  dcache_mem_wstrb;
    wire [31:0] dcache_mem_addr;
    wire [31:0] dcache_mem_wdata;
    wire        dcache_mem_addr_ok;
    wire        dcache_mem_data_ok;
    wire [31:0] dcache_mem_rdata;

    wire        icache_fetch_addr_ok;
    wire        icache_fetch_data_ok;
    wire [31:0] icache_fetch_rdata;
    wire        icache_cacop_req;
    wire        icache_cacop_addr_ok;
    wire        icache_cacop_data_ok;
    wire        dcache_req;
    wire        dcache_addr_ok;
    wire        dcache_data_ok;
    wire [31:0] dcache_rdata;

    assign icache_cacop_req = cacheop_req && exe2_cacop_is_i;
    assign dcache_req       = normal_data_sram_req || (cacheop_req && exe2_cacop_is_d);

    assign inst_sram_addr_ok = icache_fetch_addr_ok;
    assign inst_sram_data_ok = icache_fetch_data_ok;
    assign inst_sram_rdata   = icache_fetch_rdata;

    assign data_sram_addr_ok = dcache_req       ? dcache_addr_ok :
                               icache_cacop_req ? icache_cacop_addr_ok : 1'b0;
    assign data_sram_data_ok = dcache_data_ok | icache_cacop_data_ok;
    assign data_sram_rdata   = dcache_rdata;

    icache_two_way u_icache (
        .clk(clk),
        .resetn(aresetn),
        .fetch_req(inst_sram_req),
        .fetch_index(inst_sram_addr[11:4]),
        .fetch_paddr(inst_addr),
        .fetch_uncached(inst_uncached),
        .fetch_addr_ok(icache_fetch_addr_ok),
        .fetch_data_ok(icache_fetch_data_ok),
        .fetch_rdata(icache_fetch_rdata),
        .cacop_req(icache_cacop_req),
        .cacop_code(exe2_cacop_code),
        .cacop_index(data_sram_addr[11:4]),
        .cacop_paddr(data_addr),
        .cacop_way(data_sram_addr[0]),
        .cacop_addr_ok(icache_cacop_addr_ok),
        .cacop_data_ok(icache_cacop_data_ok),
        .mem_req(icache_mem_req),
        .mem_wr(icache_mem_wr),
        .mem_size(icache_mem_size),
        .mem_wstrb(icache_mem_wstrb),
        .mem_addr(icache_mem_addr),
        .mem_wdata(icache_mem_wdata),
        .mem_addr_ok(icache_mem_addr_ok),
        .mem_data_ok(icache_mem_data_ok),
        .mem_rdata(icache_mem_rdata)
    );

    dcache_two_way u_dcache (
        .clk(clk),
        .resetn(aresetn),
        .req(dcache_req),
        .op(data_sram_wr),
        .size(data_sram_size),
        .index(data_sram_addr[11:4]),
        .paddr(data_addr),
        .wstrb(data_sram_wstrb),
        .wdata(data_sram_wdata),
        .uncached(data_uncached),
        .is_cacop(cacheop_req && exe2_cacop_is_d),
        .cacop_code(exe2_cacop_code),
        .cacop_way(data_sram_addr[0]),
        .addr_ok(dcache_addr_ok),
        .data_ok(dcache_data_ok),
        .rdata(dcache_rdata),
        .mem_req(dcache_mem_req),
        .mem_wr(dcache_mem_wr),
        .mem_size(dcache_mem_size),
        .mem_wstrb(dcache_mem_wstrb),
        .mem_addr(dcache_mem_addr),
        .mem_wdata(dcache_mem_wdata),
        .mem_addr_ok(dcache_mem_addr_ok),
        .mem_data_ok(dcache_mem_data_ok),
        .mem_rdata(dcache_mem_rdata)
    );

    axi_bridge u_axi_bridge (
    .aclk(aclk),
    .aresetn(aresetn),

    .inst_sram_req(icache_mem_req),
    .inst_sram_wr(icache_mem_wr),
    .inst_sram_size(icache_mem_size),
    .inst_sram_wstrb(icache_mem_wstrb),
    .inst_sram_addr(icache_mem_addr),
    .inst_sram_wdata(icache_mem_wdata),
    .inst_sram_data_ok(icache_mem_data_ok),
    .inst_sram_addr_ok(icache_mem_addr_ok),
    .inst_sram_rdata(icache_mem_rdata),

    .data_sram_req(dcache_mem_req),
    .data_sram_wr(dcache_mem_wr),
    .data_sram_size(dcache_mem_size),
    .data_sram_wstrb(dcache_mem_wstrb),
    .data_sram_addr(dcache_mem_addr),
    .data_sram_wdata(dcache_mem_wdata),
    .data_sram_data_ok(dcache_mem_data_ok),
    .data_sram_addr_ok(dcache_mem_addr_ok),
    .data_sram_rdata(dcache_mem_rdata),

    .arid(arid),
    .araddr(araddr),
    .arlen(arlen),
    .arsize(arsize),
    .arburst(arburst),
    .arlock(arlock),
    .arcache(arcache),
    .arprot(arprot),
    .arvalid(arvalid),
    .arready(arready),

    .rid(rid),
    .rdata(rdata),
    .rvalid(rvalid),
    .rready(rready),

    .awid(awid),
    .awaddr(awaddr),
    .awlen(awlen),
    .awsize(awsize),
    .awburst(awburst),
    .awlock(awlock),
    .awcache(awcache),
    .awprot(awprot),
    .awvalid(awvalid),
    .awready(awready),

    .wid(wid),
    .wdata(wdata),
    .wstrb(wstrb),
    .wlast(wlast),
    .wvalid(wvalid),
    .wready(wready),

    .bvalid(bvalid),
    .bready(bready)
);

    wire tlb_r_e;
    wire [18:0] tlb_r_vppn;
    wire [5:0] tlb_r_ps;
    wire [9:0] tlb_r_asid;
    wire tlb_r_g;
    wire [19:0] tlb_r_ppn0;
    wire [1:0] tlb_r_plv0;
    wire [1:0] tlb_r_mat0;
    wire tlb_r_d0;
    wire tlb_r_v0;
    wire [19:0] tlb_r_ppn1;
    wire [1:0] tlb_r_plv1;
    wire [1:0] tlb_r_mat1;
    wire tlb_r_d1;
    wire tlb_r_v1;
    wire [18:0]tlb_s2_vppn;
    wire [9:0] tlb_s2_asid;
    wire tlb_s2_found;
    wire [3:0]tlb_s2_index;
    wire [3:0]tlb_w_index;

    wire tlb_w_e;
    wire [18:0]tlb_w_vppn;
    wire [5:0] tlb_w_ps;
    wire [9:0] tlb_w_asid;
    wire tlb_w_g;
    wire [19:0] tlb_w_ppn0;
    wire [1:0] tlb_w_plv0;
    wire [1:0] tlb_w_mat0;
    wire tlb_w_d0;
    wire tlb_w_v0;
    wire [19:0] tlb_w_ppn1;
    wire [1:0] tlb_w_plv1;
    wire [1:0] tlb_w_mat1;
    wire tlb_w_d1;
    wire tlb_w_v1;


    wire [18:0] tlb_s0_vppn;
    wire tlb_s0_va_bit12;
    wire [9:0] tlb_s0_asid;
    wire tlb_s0_found;
    wire [3:0] tlb_s0_index;
    wire [19:0] tlb_s0_ppn;
    wire [5:0] tlb_s0_ps;
    wire [1:0] tlb_s0_plv;
    wire [1:0] tlb_s0_mat;
    wire tlb_s0_d;
    wire tlb_s0_v;

    wire [18:0] tlb_s1_vppn;
    wire tlb_s1_va_bit12;
    wire [9:0] tlb_s1_asid;
    wire tlb_s1_found;
    wire [3:0] tlb_s1_index;
    wire [19:0] tlb_s1_ppn;
    wire [5:0] tlb_s1_ps;
    wire [1:0] tlb_s1_plv;
    wire [1:0] tlb_s1_mat;
    wire tlb_s1_d;
    wire tlb_s1_v;




    assign tlb_w_index = wb_tlb_fill_en ?  csr_timer_64[3:0] : csr_tlbidx_index ;
    assign tlb_w_e  = (csr_estat_ecode == 5'h3f) ?  1'b1 : (~csr_tlbidx_ne) ;
    assign tlb_w_vppn =  csr_tlbehi;
    assign tlb_w_ps = csr_tlbidx_ps;
    assign tlb_w_asid = csr_asid_asid;
    always @(posedge clk) begin
        if (!rst && wb_tlb_fill_en)
            $display("[TLB-FILL] %0t: w_index=%d w_vppn=%h w_ps=%h w_asid=%h w_e=%b w_g=%b ne=%b idx=%d",
                $time, tlb_w_index, tlb_w_vppn, tlb_w_ps, tlb_w_asid, tlb_w_e, tlb_w_g, csr_tlbidx_ne, csr_tlbidx_index);
    end
    always @(posedge clk) begin
        if (!rst && wb_inst_tlbrd)
            $display("[TLB-RD]  %0t: ne=%b ps=%h idx=%d tlbehi_vppn=%h r_e=%b r_ps=%h asid=%h",
                $time, csr_tlbidx_ne, csr_tlbidx_ps, csr_tlbidx_index, csr_tlbehi, tlb_r_e, tlb_r_ps, csr_asid_asid);
    end
    assign tlb_w_g = csr_tlbelo0_g & csr_tlbelo1_g;
    assign tlb_w_ppn0 = csr_tlbelo0_ppn;
    assign tlb_w_plv0 = csr_tlbelo0_plv;
    assign tlb_w_mat0 = csr_tlbelo0_mat;
    assign tlb_w_d0 = csr_tlbelo0_d;
    assign tlb_w_v0 = csr_tlbelo0_v;
    assign tlb_w_ppn1 = csr_tlbelo1_ppn;
    assign tlb_w_plv1 = csr_tlbelo1_plv;
    assign tlb_w_mat1 = csr_tlbelo1_mat;
    assign tlb_w_d1 = csr_tlbelo1_d;
    assign tlb_w_v1 = csr_tlbelo1_v;

    assign tlb_s2_asid = wb_inst_tlbsrch ? csr_asid_asid : wb_invtlb_asid;
    assign tlb_s2_vppn = wb_inst_tlbsrch ? csr_tlbehi  :  wb_invtlb_va  ;


    //  search ports for fetch and load/store
    assign tlb_s0_vppn = inst_sram_addr [31:13];
    assign tlb_s0_va_bit12  = inst_sram_addr [12];
    assign tlb_s0_asid = csr_asid_asid;

    assign tlb_s1_vppn = data_sram_addr [31:13];
    assign tlb_s1_va_bit12 = data_sram_addr [12];
    assign tlb_s1_asid = csr_asid_asid;

    tlb u_tlb (
    .clk(clk),
    .rst(rst),

    //  search ports0(for fetch)
    .s0_vppn(tlb_s0_vppn),            //虚拟访存地址�?????31....13�?????
    .s0_va_bit12(tlb_s0_va_bit12),                //虚拟访存地址的第12�??
    .s0_asid(tlb_s0_asid),              //  CSR的ASID域，用于多线程比�??
    .s0_found(tlb_s0_found),                //用于判断重填异常，页无效异常，特权等级不合规异常，页修改异常
    .s0_index(tlb_s0_index),         // 用于TLBSRCH指令，查找在第几�??
    .s0_ppn(tlb_s0_ppn),                //用于产生物理地址
    .s0_ps(tlb_s0_ps),                  //用于产生物理地址
    .s0_plv(tlb_s0_plv),                 //用于判断特权等级不合规异�??
    .s0_mat(tlb_s0_mat),
    .s0_d(tlb_s0_d),                          //用于判断页修改异�??
    .s0_v(tlb_s0_v),                           //用于判断页无效异常，页修改异�??

    //  search ports1(for load/store)
    .s1_vppn(tlb_s1_vppn),            //虚拟访存地址�?????31....13�?????
    .s1_va_bit12(tlb_s1_va_bit12),                //虚拟访存地址的第12�??
    .s1_asid(tlb_s1_asid),              //  CSR的ASID域，用于多线程比�??
    .s1_found(tlb_s1_found),                //用于判断重填异常，页无效异常，特权等级不合规异常，页修改异常
    .s1_index(tlb_s1_index),       // 用于TLBSRCH指令，查找在第几�??
    .s1_ppn(tlb_s1_ppn),                //用于产生物理地址
    .s1_ps(tlb_s1_ps),                  //用于产生物理地址
    .s1_plv(tlb_s1_plv),                 //用于判断特权等级不合规异�??
    .s1_mat(tlb_s1_mat),
    .s1_d(tlb_s1_d),                          //用于判断页修改异�??
    .s1_v(tlb_s1_v),                           //用于判断页无效异常，页修改异�??

    // search ports three
    .s2_vppn(tlb_s2_vppn),
    .s2_asid(tlb_s2_asid),
    .s2_found(tlb_s2_found),
    .s2_index(tlb_s2_index),

    //write port
    .we(wb_tlb_we),                           //写使�??
    .w_index(tlb_w_index),       //写的地址
    .w_e(tlb_w_e),                               //写数�??
    .w_vppn(tlb_w_vppn),                      //要写的虚双页
    .w_ps(tlb_w_ps),                       //要写的PS
    .w_asid(tlb_w_asid),                     // 要写的ASID
    .w_g(tlb_w_g),                             //要写的G
    .w_ppn0(tlb_w_ppn0),                  //要写的ppn0
    .w_plv0(tlb_w_plv0),                     //要写的plv0
    .w_mat0(tlb_w_mat0),                     //要写的mat0
    .w_d0(tlb_w_d0),                           //要写的d0
    .w_v0(tlb_w_v0),                             //要写的v0
    .w_ppn1(tlb_w_ppn1),                   //要写的ppn1
    .w_plv1(tlb_w_plv1),                     //要写的plv1
    .w_mat1(tlb_w_mat1),                    //要写的mat1
    .w_d1(tlb_w_d1),                            //要写的d1
    .w_v1(tlb_w_v1),                            //要写的v1

    //read port
    .r_index(csr_tlbidx_index),                  //读的地址
    .r_e(tlb_r_e),                               //读数据的e
    .r_vppn(tlb_r_vppn),                      //要读的虚双页
    .r_ps(tlb_r_ps),                       //要读的PS
    .r_asid(tlb_r_asid),                     // 要读的ASID
    .r_g(tlb_r_g),                             //要读的G
    .r_ppn0(tlb_r_ppn0),                  //要读的ppn0
    .r_plv0(tlb_r_plv0),                     //要读的plv0
    .r_mat0(tlb_r_mat0),                     //要读的mat0
    .r_d0(tlb_r_d0),                           //要读的d0
    .r_v0(tlb_r_v0),                             //要读的v0
    .r_ppn1(tlb_r_ppn1),                   //要读的ppn1
    .r_plv1(tlb_r_plv1),                     //要读的plv1
    .r_mat1(tlb_r_mat1),                    //要读的mat1
    .r_d1(tlb_r_d1),                            //要读的d1
    .r_v1(tlb_r_v1),                            //要读的v1

    //invtlb opcode
    .invtlb_valid(wb_invtlb_valid),                     //用于Invtlb指令
    .invtlb_op(wb_invtlb_op)                 //Invtlb指令的操作码
);

    wire tlbrd_entry_valid = wb_inst_tlbrd && !csr_tlbidx_index_invalid && tlb_r_e;

    assign csr_tlbehi_we = wb_inst_tlbrd ? 1'b1 : 1'b0;
    assign csr_tlbehi_wvalue = tlbrd_entry_valid ?  tlb_r_vppn : 19'b0;

    assign csr_tlbelo0_g_we = wb_inst_tlbrd ? 1'b1 : 1'b0;
    assign csr_tlbelo0_g_wvalue   =  tlbrd_entry_valid ?  tlb_r_g : 1'b0;


    assign csr_tlbelo0_d_we = wb_inst_tlbrd ? 1'b1 : 1'b0;
    assign csr_tlbelo0_d_wvalue = tlbrd_entry_valid ?  tlb_r_d0 : 1'b0;


    assign csr_tlbelo0_v_we = wb_inst_tlbrd ? 1'b1 : 1'b0;
    assign csr_tlbelo0_v_wvalue = tlbrd_entry_valid ?  tlb_r_v0 : 1'b0;


    assign csr_tlbelo0_plv_we = wb_inst_tlbrd ? 1'b1 : 1'b0;
    assign csr_tlbelo0_plv_wvalue = tlbrd_entry_valid ?  tlb_r_plv0 : 2'b0;


    assign csr_tlbelo0_mat_we = wb_inst_tlbrd ? 1'b1 : 1'b0;
    assign csr_tlbelo0_mat_wvalue =  tlbrd_entry_valid ?  tlb_r_mat0 : 2'b0;


    assign csr_tlbelo0_ppn_we = wb_inst_tlbrd ? 1'b1 : 1'b0;
    assign csr_tlbelo0_ppn_wvalue = tlbrd_entry_valid ?  tlb_r_ppn0 : 20'b0;


    assign csr_tlbelo1_g_we = wb_inst_tlbrd ? 1'b1 : 1'b0;
    assign csr_tlbelo1_g_wvalue   =  tlbrd_entry_valid ?  tlb_r_g : 1'b0;


    assign csr_tlbelo1_d_we = wb_inst_tlbrd ? 1'b1 : 1'b0;
    assign csr_tlbelo1_d_wvalue = tlbrd_entry_valid ?  tlb_r_d1 : 1'b0;


    assign csr_tlbelo1_v_we = wb_inst_tlbrd ? 1'b1 : 1'b0;
    assign csr_tlbelo1_v_wvalue = tlbrd_entry_valid ?  tlb_r_v1 : 1'b0;


    assign csr_tlbelo1_plv_we = wb_inst_tlbrd ? 1'b1 : 1'b0;
    assign csr_tlbelo1_plv_wvalue = tlbrd_entry_valid ?  tlb_r_plv1 : 2'b0;


    assign csr_tlbelo1_mat_we = wb_inst_tlbrd ? 1'b1 : 1'b0;
    assign csr_tlbelo1_mat_wvalue =  tlbrd_entry_valid ?  tlb_r_mat1: 2'b0;


    assign csr_tlbelo1_ppn_we = wb_inst_tlbrd ? 1'b1 : 1'b0;
    assign csr_tlbelo1_ppn_wvalue = tlbrd_entry_valid ?  tlb_r_ppn1 : 20'b0;


    assign csr_tlbidx_ps_we =  wb_inst_tlbrd ? 1'b1 : 1'b0;
    assign csr_tlbidx_ps_wvalue = tlbrd_entry_valid ?  tlb_r_ps : 6'b0;


    assign csr_tlbidx_ne_we =  (wb_inst_tlbrd || wb_inst_tlbsrch) ? 1'b1 : 1'b0;
    assign csr_tlbidx_ne_wvalue = tlbrd_entry_valid ?  1'b0 :
                                  (wb_inst_tlbrd && tlb_r_e!=1'b1 )?   1'b1 :
                                  (wb_inst_tlbsrch && tlb_s2_found) ?  1'b0: 1'b1;


    assign csr_asid_asid_we =  wb_inst_tlbrd  ? 1'b1 : 1'b0;
    assign csr_asid_asid_wvalue =  tlbrd_entry_valid ?   tlb_r_asid : 10'b0  ;

    assign csr_tlbidx_index_we = (wb_inst_tlbsrch && tlb_s2_found);
    assign csr_tlbidx_index_wvalue  = tlb_s2_index;

    // ============================================================
    // Pipeline stall debug outputs
    // ============================================================
    assign debug_id_allow_in     = id_allow_in;
    assign debug_id_ready_go     = id_ready_go;
    assign debug_exe1_allow_in   = exe1_allow_in;
    assign debug_exe2_allow_in   = exe2_allow_in;
    assign debug_mem_allow_in    = mem_allow_in;
    assign debug_if_ready_go     = if_ready_go;
    assign debug_pipe_stalled    = ~pipline_is_not_stalled;
    assign debug_wb_ex           = wb_ex;
    assign debug_id_pc           = id_pc;
    assign debug_id_inst         = id_inst;
    assign debug_id_rj           = id_rj;
    assign debug_id_rk           = id_rk;
    assign debug_id_rd           = id_rd;
    assign debug_id_src1_from_ref = id_src1_from_ref;
    assign debug_id_src2_from_ref = id_src2_from_ref;
    assign debug_exe2_rd         = exe2_rd;
    assign debug_exe2_ref_we     = exe2_ref_we;
    assign debug_mem_rd          = mem_rd;
    assign debug_mem_ref_we      = mem_ref_we;
    assign debug_wb_rd           = wb_rd;
    assign debug_wb_rf_we_dbg    = wb_rf_we;

`ifdef DIFFTEST_EN
    // ============================================================
    // Difftest signal extraction and DPI module integration
    // ============================================================

    // WB-stage difftest signals
    wire        wb_valid;
    wire        wb_is_load;
    wire        wb_is_store;
    wire        wb_csr_rstat;
    wire        wb_is_tlbfill;
    wire [3:0]  wb_tlbfill_index;

    assign wb_valid        = (wb_pc != 32'h1bfffffc) && (wb_pc != 32'b0) && !wb_need_cancel;
    assign wb_is_load      = (wb_dram_we == 1'b0) && (wb_rdram_num != 2'b0 || wb_res_from_dram);
    assign wb_is_store     = (wb_dram_we == 1'b1);
    assign wb_csr_rstat    = (wb_csr_we == 1'b0) && (wb_csr_num == 14'h5) && wb_valid;
    assign wb_is_tlbfill   = wb_tlb_fill_en && wb_valid;
    assign wb_tlbfill_index = csr_timer_64[3:0];

    // cmt_* staging registers (1-cycle delay)
    reg         cmt_valid;
    reg         cmt_cnt_instr;
    reg [63:0]  cmt_stable_counter;
    reg         cmt_inst_ld_en;
    reg         cmt_inst_st_en;
    reg [31:0]  cmt_memvis_paddr;
    reg [31:0]  cmt_memvis_vaddr;
    reg [31:0]  cmt_memvis_data;
    reg         cmt_csr_rstat_en;
    // cmt_csr_all removed: DifftestCSRRegState connects to wire csr_all_diff directly
    // to avoid NBA race with CSR register writes (wb_csr_we updates CSR at same posedge)
    reg         cmt_wen;
    reg [7:0]   cmt_wdest;
    reg [31:0]  cmt_wdata;
    reg [31:0]  cmt_pc;
    reg [31:0]  cmt_inst;
    reg         cmt_ex;
    reg         cmt_is_ertn;
    reg [5:0]   cmt_ecode;
    reg         cmt_is_tlbfill;
    reg [3:0]   cmt_tlbfill_index;

    reg         trap;
    reg [7:0]   trap_code;
    reg [63:0]  cycleCnt;
    reg [63:0]  instrCnt;

    always @(posedge aclk) begin
        if (!aresetn) begin
            {cmt_valid, cmt_cnt_instr, cmt_inst_ld_en, cmt_inst_st_en,
             cmt_csr_rstat_en, cmt_wen, cmt_ex, cmt_is_ertn, cmt_is_tlbfill} <= 0;
            cmt_stable_counter <= 64'd0;
            {cmt_memvis_paddr, cmt_memvis_vaddr, cmt_memvis_data} <= 0;
            {cmt_wdest, cmt_wdata, cmt_pc, cmt_inst} <= 0;
            {cmt_ecode, cmt_tlbfill_index} <= 0;
            {trap, trap_code, cycleCnt, instrCnt} <= 0;
        end else if (~trap) begin
            cmt_valid           <= wb_valid && !wb_ex;
            cmt_cnt_instr       <= wb_res_from_cnt;
            cmt_stable_counter  <= csr_timer_64;
            cmt_inst_ld_en      <= wb_is_load;
            cmt_inst_st_en      <= wb_is_store;
            cmt_memvis_paddr    <= wb_data_addr;
            cmt_memvis_vaddr    <= wb_data_addr;
            // Mask store data to actual size with correct byte lane alignment
            // st.b: 1 byte at addr[1:0] lane; st.h: 2 bytes at addr[1] halfword
            cmt_memvis_data     <= (wb_wdram_num == 2'b01) ? ({24'b0, wb_dram_wdata[7:0]} << (8 * wb_data_addr[1:0])) :
                                   (wb_wdram_num == 2'b10) ? ({16'b0, wb_dram_wdata[15:0]} << (8 * {wb_data_addr[1], 1'b0})) :
                                   wb_dram_wdata;
            cmt_csr_rstat_en    <= wb_csr_rstat;
            cmt_wen             <= wb_rf_we;
            cmt_wdest           <= {3'd0, wb_rd};
            cmt_wdata           <= rf_wdata;
            cmt_pc              <= debug0_wb_pc;
            cmt_inst            <= wb_inst;
            cmt_ex              <= wb_valid && wb_ex;
            cmt_is_ertn         <= wb_is_ertn;
            cmt_ecode           <= wb_ecode;
            cmt_is_tlbfill      <= wb_is_tlbfill;
            cmt_tlbfill_index   <= wb_tlbfill_index;
            trap                <= 1'b0;
            trap_code           <= gp_regs_diff[10][7:0];
            cycleCnt            <= cycleCnt + 1;
            instrCnt            <= instrCnt + (wb_valid ? 1 : 0);
        end
    end

    // Difftest DPI module instantiations
    DifftestInstrCommit DifftestInstrCommit(
        .clock              (aclk               ),
        .coreid             (0                  ),
        .index              (0                  ),
        .valid              (cmt_valid          ),
        .pc                 (cmt_pc             ),
        .instr              (cmt_inst           ),
        .skip               (0                  ),
        .is_TLBFILL         (cmt_is_tlbfill     ),
        .TLBFILL_index      (cmt_tlbfill_index  ),
        .is_CNTinst         (cmt_cnt_instr      ),
        .timer_64_value     (cmt_stable_counter ),
        .wen                (cmt_wen            ),
        .wdest              (cmt_wdest          ),
        .wdata              (cmt_wdata          ),
        .csr_rstat          (cmt_csr_rstat_en   ),
        .csr_data           (cmt_wdata          )
    );

    DifftestExcpEvent DifftestExcpEvent(
        .clock              (aclk               ),
        .coreid             (0                  ),
        .excp_valid         (cmt_ex             ),
        .eret               (cmt_is_ertn        ),
        .intrNo             (csr_all_diff[716:706]),
        .cause              (cmt_ecode          ),
        .exceptionPC        (cmt_pc             ),
        .exceptionInst      (cmt_inst           )
    );

    DifftestTrapEvent DifftestTrapEvent(
        .clock              (aclk               ),
        .coreid             (0                  ),
        .valid              (trap               ),
        .code               (trap_code          ),
        .pc                 (cmt_pc             ),
        .cycleCnt           (cycleCnt           ),
        .instrCnt           (instrCnt           )
    );

    DifftestStoreEvent DifftestStoreEvent(
        .clock              (aclk               ),
        .coreid             (0                  ),
        .index              (0                  ),
        .valid              (cmt_inst_st_en     ),
        .storePAddr         (cmt_memvis_paddr   ),
        .storeVAddr         (cmt_memvis_vaddr   ),
        .storeData          (cmt_memvis_data    )
    );

    DifftestLoadEvent DifftestLoadEvent(
        .clock              (aclk               ),
        .coreid             (0                  ),
        .index              (0                  ),
        .valid              (cmt_inst_ld_en     ),
        .paddr              (cmt_memvis_paddr   ),
        .vaddr              (cmt_memvis_vaddr   )
    );

    DifftestCSRRegState DifftestCSRRegState(
        .clock              (aclk               ),
        .coreid             (0                  ),
        .crmd               (csr_all_diff[831:800]),
        .prmd               (csr_all_diff[799:768]),
        .euen               (0                  ),
        .ecfg               (csr_all_diff[767:736]),
        .estat              (csr_all_diff[735:704]),
        .era                (csr_all_diff[703:672]),
        .badv               (csr_all_diff[671:640]),
        .eentry             (csr_all_diff[639:608]),
        .tlbidx             (csr_all_diff[607:576]),
        .tlbehi             (csr_all_diff[575:544]),
        .tlbelo0            (csr_all_diff[543:512]),
        .tlbelo1            (csr_all_diff[511:480]),
        .asid               (csr_all_diff[479:448]),
        .pgdl               (csr_all_diff[447:416]),
        .pgdh               (csr_all_diff[415:384]),
        .save0              (csr_all_diff[383:352]),
        .save1              (csr_all_diff[351:320]),
        .save2              (csr_all_diff[319:288]),
        .save3              (csr_all_diff[287:256]),
        .tid                (csr_all_diff[255:224]),
        .tcfg               (csr_all_diff[223:192]),
        .tval               (csr_all_diff[191:160]),
        .ticlr              (csr_all_diff[159:128]),
        .llbctl             (csr_all_diff[127:96]),
        .tlbrentry          (csr_all_diff[95:64]),
        .dmw0               (csr_all_diff[63:32]),
        .dmw1               (csr_all_diff[31:0])
    );

    DifftestGRegState DifftestGRegState(
        .clock              (aclk               ),
        .coreid             (0                  ),
        .gpr_0              (0                  ),
        .gpr_1              (gp_regs_diff[1]    ),
        .gpr_2              (gp_regs_diff[2]    ),
        .gpr_3              (gp_regs_diff[3]    ),
        .gpr_4              (gp_regs_diff[4]    ),
        .gpr_5              (gp_regs_diff[5]    ),
        .gpr_6              (gp_regs_diff[6]    ),
        .gpr_7              (gp_regs_diff[7]    ),
        .gpr_8              (gp_regs_diff[8]    ),
        .gpr_9              (gp_regs_diff[9]    ),
        .gpr_10             (gp_regs_diff[10]   ),
        .gpr_11             (gp_regs_diff[11]   ),
        .gpr_12             (gp_regs_diff[12]   ),
        .gpr_13             (gp_regs_diff[13]   ),
        .gpr_14             (gp_regs_diff[14]   ),
        .gpr_15             (gp_regs_diff[15]   ),
        .gpr_16             (gp_regs_diff[16]   ),
        .gpr_17             (gp_regs_diff[17]   ),
        .gpr_18             (gp_regs_diff[18]   ),
        .gpr_19             (gp_regs_diff[19]   ),
        .gpr_20             (gp_regs_diff[20]   ),
        .gpr_21             (gp_regs_diff[21]   ),
        .gpr_22             (gp_regs_diff[22]   ),
        .gpr_23             (gp_regs_diff[23]   ),
        .gpr_24             (gp_regs_diff[24]   ),
        .gpr_25             (gp_regs_diff[25]   ),
        .gpr_26             (gp_regs_diff[26]   ),
        .gpr_27             (gp_regs_diff[27]   ),
        .gpr_28             (gp_regs_diff[28]   ),
        .gpr_29             (gp_regs_diff[29]   ),
        .gpr_30             (gp_regs_diff[30]   ),
        .gpr_31             (gp_regs_diff[31]   )
    );
`endif

endmodule
