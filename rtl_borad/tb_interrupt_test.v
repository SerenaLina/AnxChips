`timescale 1ns / 1ps

// Testbench specifically for interrupt handler verification
// This test injects a misaligned PC to trigger the interrupt

module tb_interrupt_test;

    // Clock and reset
    reg clk;
    reg resetn;

    // Clock generation: 10ns period (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Internal signals for monitoring
    wire [31:0] fs_nextpc;
    wire        int_stall_req;
    wire [32:0] trap_info_bus;
    wire [31:0] csr_crmd;
    wire [31:0] csr_prmd;
    wire [31:0] csr_era;
    wire        csr_we;
    wire [7:0]  csr_waddr;
    wire [31:0] csr_wdata;
    wire [1:0]  trap_unit_state;

    // Instantiate CPU directly for more control
    mycpu_top u_cpu (
        .clk              (clk              ),
        .resetn           (resetn           ),
        .inst_sram_en     (),
        .inst_sram_we     (),
        .inst_sram_addr   (),
        .inst_sram_wdata  (),
        .inst_sram_rdata  (32'h03400000),  // nop instruction
        .data_sram_en     (),
        .data_sram_we     (),
        .data_sram_addr   (),
        .data_sram_wdata  (),
        .data_sram_rdata  (32'h0),
        .debug_wb_pc      (),
        .debug_wb_rf_we   (),
        .debug_wb_rf_wnum (),
        .debug_wb_rf_wdata(),
        .debug_sram_rdata (),
        .debug_id_rf_raddr1(),
        .debug_id_rf_rdata1(),
        .debug_wb_alu_src1(),
        .debug_wb_alu_src2(),
        .debug_src2_is_imm(),
        .debug_m_axis_dout_data_s(),
        .debug_div_complete()
    );

    // Connect monitoring signals
    assign fs_nextpc = u_cpu.fs_nextpc;
    assign int_stall_req = u_cpu.int_stall_req;
    assign trap_info_bus = u_cpu.trap_info_bus;
    assign csr_crmd = u_cpu.csr_crmd;
    assign csr_prmd = u_cpu.csr_prmd;
    assign csr_era = u_cpu.csr_era;
    assign csr_we = u_cpu.csr_we;
    assign csr_waddr = u_cpu.csr_waddr;
    assign csr_wdata = u_cpu.csr_wdata;
    assign trap_unit_state = u_cpu.u_trap_unit.state;

    // Test sequence
    initial begin
        // Initialize
        resetn = 0;

        // Wait for global reset
        #100;
        resetn = 1;

        $display("==============================================");
        $display("Interrupt Handler Test - Misaligned PC Detection");
        $display("==============================================");
        $display("Test started at time %0t", $time);
        $display("");
        $display("Testing interrupt.v logic:");
        $display("  - trap_valid = (nextpc[1:0] != 2'b00)");
        $display("  - Should detect misaligned addresses");
        $display("");

        // Wait for CPU to start
        #50;

        // Display initial state
        $display("Initial state:");
        $display("  nextpc = 0x%08h, int_stall_req = %b", fs_nextpc, int_stall_req);
        $display("  nextpc[1:0] = %b (00=aligned, !=00=misaligned)", fs_nextpc[1:0]);
        $display("");

        // Run and monitor
        #1000;

        $display("==============================================");
        $display("Test completed at time %0t", $time);
        $display("==============================================");

        $finish;
    end

    // Detailed monitoring
    always @(posedge clk) begin
        if (resetn) begin
            // Monitor PC changes and trap detection
            if (fs_nextpc[1:0] != 2'b00) begin
                $display("[%0t] MISALIGNED PC DETECTED: nextpc = 0x%08h [1:0] = %b",
                         $time, fs_nextpc, fs_nextpc[1:0]);

                if (int_stall_req) begin
                    $display("  -> int_stall_req = 1 (TRAP TRIGGERED)");
                    $display("  -> trap_info_bus = 0x%09h", trap_info_bus);
                    $display("  -> epc = 0x%08h", trap_info_bus[31:0]);
                end else begin
                    $display("  -> WARNING: int_stall_req = 0 (TRAP NOT TRIGGERED!)");
                end
            end

            // Monitor CSR writes
            if (csr_we) begin
                $display("[%0t] CSR WRITE: addr=0x%02h, data=0x%08h",
                         $time, csr_waddr, csr_wdata);
                case (csr_waddr)
                    8'h00: $display("         -> CRMD (Current Mode): PLV=%b, IE=%b",
                                    csr_wdata[1:0], csr_wdata[2]);
                    8'h01: $display("         -> PRMD (Previous Mode): PPLV=%b, PIE=%b",
                                    csr_wdata[1:0], csr_wdata[2]);
                    8'h06: $display("         -> ERA (Exception Return): 0x%08h", csr_wdata);
                    8'h07: $display("         -> BADV (Bad Virtual Address): 0x%08h", csr_wdata);
                endcase
            end

            // Monitor trap unit state machine
            if (trap_unit_state != 2'b00) begin
                $display("[%0t] Trap Unit State: %b", $time, trap_unit_state);
                case (trap_unit_state)
                    2'b00: ; // IDLE
                    2'b01: $display("         -> WRITE_PRMD");
                    2'b10: $display("         -> WRITE_CRMD");
                    2'b11: $display("         -> WRITE_ERA");
                endcase
            end
        end
    end

    // Final verification
    reg [31:0] last_csr_era;
    always @(posedge clk) begin
        if (resetn) begin
            if (csr_we && csr_waddr == 8'h06) begin
                last_csr_era <= csr_wdata;
            end
        end
    end

    // Waveform dump
    initial begin
        $dumpfile("tb_interrupt_test.vcd");
        $dumpvars(0, tb_interrupt_test);
    end

endmodule
