`include "mycpu.h"

module soc_top (
    input         clk,
    input         resetn
);

    // Reset signal
    reg reset;
    always @(posedge clk) reset <= ~resetn;

    // CPU signals
    wire        inst_sram_en;
    wire [ 3:0] inst_sram_we;
    wire [31:0] inst_sram_addr;
    wire [31:0] inst_sram_wdata;
    wire [31:0] inst_sram_rdata;

    wire        data_sram_en;
    wire [ 3:0] data_sram_we;
    wire [31:0] data_sram_addr;
    wire [31:0] data_sram_wdata;
    wire [31:0] data_sram_rdata;

    // Debug signals
    wire [31:0] debug_wb_pc;
    wire [ 3:0] debug_wb_rf_we;
    wire [ 4:0] debug_wb_rf_wnum;
    wire [31:0] debug_wb_rf_wdata;

    // CPU instantiation
    mycpu_top u_cpu (
        .clk              (clk              ),
        .resetn           (resetn           ),
        .inst_sram_en     (inst_sram_en     ),
        .inst_sram_we     (inst_sram_we     ),
        .inst_sram_addr   (inst_sram_addr   ),
        .inst_sram_wdata  (inst_sram_wdata  ),
        .inst_sram_rdata  (inst_sram_rdata  ),
        .data_sram_en     (data_sram_en     ),
        .data_sram_we     (data_sram_we     ),
        .data_sram_addr   (data_sram_addr   ),
        .data_sram_wdata  (data_sram_wdata  ),
        .data_sram_rdata  (data_sram_rdata  ),
        .debug_wb_pc      (debug_wb_pc      ),
        .debug_wb_rf_we   (debug_wb_rf_we   ),
        .debug_wb_rf_wnum (debug_wb_rf_wnum ),
        .debug_wb_rf_wdata(debug_wb_rf_wdata),
        .debug_sram_rdata (),
        .debug_id_rf_raddr1(),
        .debug_id_rf_rdata1(),
        .debug_wb_alu_src1(),
        .debug_wb_alu_src2(),
        .debug_src2_is_imm(),
        .debug_m_axis_dout_data_s(),
        .debug_div_complete()
    );

    // Instruction SRAM (4KB = 1024 x 32bit)
    reg [31:0] inst_ram [0:1023];

    // Data SRAM (4KB = 1024 x 32bit)
    reg [31:0] data_ram [0:1023];

    // Instruction SRAM read/write logic
    wire [9:0] inst_ram_addr = inst_sram_addr[11:2];

    always @(posedge clk) begin
        if (inst_sram_en) begin
            if (|inst_sram_we) begin
                // Write operation (if needed)
                if (inst_sram_we[0]) inst_ram[inst_ram_addr][ 7: 0] <= inst_sram_wdata[ 7: 0];
                if (inst_sram_we[1]) inst_ram[inst_ram_addr][15: 8] <= inst_sram_wdata[15: 8];
                if (inst_sram_we[2]) inst_ram[inst_ram_addr][23:16] <= inst_sram_wdata[23:16];
                if (inst_sram_we[3]) inst_ram[inst_ram_addr][31:24] <= inst_sram_wdata[31:24];
            end
        end
    end

    assign inst_sram_rdata = inst_ram[inst_ram_addr];

    // Data SRAM read/write logic
    wire [9:0] data_ram_addr = data_sram_addr[11:2];

    always @(posedge clk) begin
        if (data_sram_en) begin
            if (|data_sram_we) begin
                // Byte-wise write
                if (data_sram_we[0]) data_ram[data_ram_addr][ 7: 0] <= data_sram_wdata[ 7: 0];
                if (data_sram_we[1]) data_ram[data_ram_addr][15: 8] <= data_sram_wdata[15: 8];
                if (data_sram_we[2]) data_ram[data_ram_addr][23:16] <= data_sram_wdata[23:16];
                if (data_sram_we[3]) data_ram[data_ram_addr][31:24] <= data_sram_wdata[31:24];
            end
        end
    end

    assign data_sram_rdata = data_ram[data_ram_addr];

    // Initialize memories from file
    initial begin
        $readmemh("inst_ram.hex", inst_ram);
        $readmemh("data_ram.hex", data_ram);
    end

endmodule
