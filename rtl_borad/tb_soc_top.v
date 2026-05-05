`timescale 1ns / 1ps

module tb_soc_top;

    // Clock and reset
    reg clk;
    reg resetn;

    // Clock generation: 10ns period (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // DUT instantiation
    soc_top u_soc (
        .clk    (clk    ),
        .resetn (resetn )
    );

    // Test variables
    integer cycle_count;
    reg test_passed;
    reg trap_detected;
    reg csr_updated;

    // Monitor signals from CPU
    wire [31:0] fs_nextpc = u_soc.u_cpu.fs_nextpc;
    wire        int_stall_req = u_soc.u_cpu.int_stall_req;
    wire [32:0] trap_info_bus = u_soc.u_cpu.trap_info_bus;
    wire [31:0] csr_crmd = u_soc.u_cpu.csr_crmd;
    wire [31:0] csr_prmd = u_soc.u_cpu.csr_prmd;
    wire [31:0] csr_era = u_soc.u_cpu.csr_era;
    wire        csr_we = u_soc.u_cpu.csr_we;
    wire [7:0]  csr_waddr = u_soc.u_cpu.csr_waddr;
    wire [31:0] csr_wdata = u_soc.u_cpu.csr_wdata;
    wire [31:0] debug_wb_pc = u_soc.u_cpu.debug_wb_pc;
    wire [1:0]  trap_unit_state = u_soc.u_cpu.u_trap_unit.state;

    // Force misaligned PC
    reg force_misaligned_pc;
    reg [31:0] forced_pc_value;

    // Test sequence
    initial begin
        // Initialize
        resetn = 0;
        cycle_count = 0;
        test_passed = 1;
        trap_detected = 0;
        csr_updated = 0;
        force_misaligned_pc = 0;
        forced_pc_value = 32'h0;

        // Initialize instruction memory with test program
        // Program at 0x1c000000:
        //  0x1c000000: nop
        //  0x1c000004: nop
        //  0x1c000008: nop
        //  0x1c00000c: nop
        //  ...
        u_soc.inst_ram[0]  = 32'h03400000;  // nop (add.w $r0, $r0, $r0)
        u_soc.inst_ram[1]  = 32'h03400000;  // nop
        u_soc.inst_ram[2]  = 32'h03400000;  // nop
        u_soc.inst_ram[3]  = 32'h03400000;  // nop
        u_soc.inst_ram[4]  = 32'h03400000;  // nop
        u_soc.inst_ram[5]  = 32'h03400000;  // nop
        u_soc.inst_ram[6]  = 32'h03400000;  // nop
        u_soc.inst_ram[7]  = 32'h03400000;  // nop

        // Fill rest with nops
        for (integer i = 8; i < 1024; i = i + 1) begin
            u_soc.inst_ram[i] = 32'h03400000;
        end

        // Clear data memory
        for (integer i = 0; i < 1024; i = i + 1) begin
            u_soc.data_ram[i] = 32'h0;
        end

        // Wait for global reset
        #100;
        resetn = 1;

        $display("==============================================");
        $display("Test: Interrupt Handler with Misaligned PC");
        $display("==============================================");
        $display("Test started at time %0t", $time);
        $display("");
        $display("Test Program: All NOPs at 0x1c000000+");
        $display("");
        $display("Phase 1: Normal execution (aligned PC)");
        $display("----------------------------------------------");

        // Wait for normal execution
        #100;

        $display("");
        $display("Phase 2: Force misaligned PC");
        $display("----------------------------------------------");
        $display("Forcing nextpc = 0x1c000001 (misaligned!)");
        $display("Expected: int_stall_req = 1 (trap triggered)");
        $display("");

        // Force misaligned PC
        force_misaligned_pc = 1;
        forced_pc_value = 32'h1c000001;  // Misaligned address
        #20;
        force_misaligned_pc = 0;

        // Wait and observe
        #500;

        // Check results
        $display("");
        $display("==============================================");
        $display("Test Results:");
        $display("  Trap detected: %b", trap_detected);
        $display("  CSR updated: %b", csr_updated);
        if (trap_detected && csr_updated) begin
            $display("  TEST PASSED!");
        end else begin
            $display("  TEST FAILED!");
            test_passed = 0;
        end
        $display("  Total cycles: %0d", cycle_count);
        $display("==============================================");

        $finish;
    end

    // Cycle counter
    always @(posedge clk) begin
        if (resetn) begin
            cycle_count <= cycle_count + 1;
        end
    end

    // Force misaligned PC at specific cycle
    always @(posedge clk) begin
        if (resetn && cycle_count == 20) begin
            force u_soc.u_cpu.fs_nextpc = 32'h1c000001;
            $display("[%0t] FORCED: fs_nextpc = 0x1c000001 (misaligned)", $time);
        end else if (resetn && cycle_count == 21) begin
            release u_soc.u_cpu.fs_nextpc;
        end
    end

    // Monitor and display key signals
    always @(posedge clk) begin
        if (resetn) begin
            // Display every 10 cycles or when interesting events happen
            if (cycle_count % 10 == 0 || int_stall_req || csr_we) begin
                $display("[%0t] Cycle=%0d: nextpc=0x%08h [1:0]=%b, int_stall=%b",
                         $time, cycle_count, fs_nextpc, fs_nextpc[1:0], int_stall_req);

                if (int_stall_req) begin
                    $display("  [TRAP DETECTED] trap_info_bus=0x%09h", trap_info_bus);
                    $display("  EPC captured: 0x%08h", trap_info_bus[31:0]);
                    trap_detected <= 1;
                end

                if (csr_we) begin
                    $display("  [CSR WRITE] addr=0x%02h, data=0x%08h", csr_waddr, csr_wdata);
                    case (csr_waddr)
                        8'h00: begin
                            $display("    -> CRMD (Current Mode): PLV=%b, IE=%b",
                                    csr_wdata[1:0], csr_wdata[2]);
                            csr_updated <= 1;
                        end
                        8'h01: begin
                            $display("    -> PRMD (Previous Mode): PPLV=%b, PIE=%b",
                                    csr_wdata[1:0], csr_wdata[2]);
                            $display("       Previous CRMD saved: PLV=%b, IE=%b",
                                    csr_wdata[1:0], csr_wdata[2]);
                        end
                        8'h06: $display("    -> ERA (Exception Return): 0x%08h", csr_wdata);
                        8'h07: $display("    -> BADV (Bad Virtual Address): 0x%08h", csr_wdata);
                    endcase
                end
            end
        end
    end

    // Monitor trap unit state machine
    always @(posedge clk) begin
        if (resetn && trap_unit_state != 2'b00) begin
            case (trap_unit_state)
                2'b01: $display("[%0t] Trap Unit: WRITE_PRMD state", $time);
                2'b10: $display("[%0t] Trap Unit: WRITE_CRMD state", $time);
                2'b11: $display("[%0t] Trap Unit: WRITE_ERA state", $time);
            endcase
        end
    end

    // Check CSR values after trap handling
    always @(posedge clk) begin
        if (resetn && cycle_count == 80) begin
            $display("");
            $display("[%0t] Final CSR Status:", $time);
            $display("  CRMD = 0x%08h (PLV=%b, IE=%b)", csr_crmd, csr_crmd[1:0], csr_crmd[2]);
            $display("  PRMD = 0x%08h (PPLV=%b, PIE=%b)", csr_prmd, csr_prmd[1:0], csr_prmd[2]);
            $display("  ERA  = 0x%08h", csr_era);
            $display("");

            // Verify results
            if (csr_era == 32'h1c000001) begin
                $display("  [OK] ERA correctly saved the misaligned PC");
            end else begin
                $display("  [ERROR] ERA = 0x%08h, expected 0x1c000001", csr_era);
            end

            if (csr_crmd[2] == 1'b0) begin
                $display("  [OK] CRMD.IE = 0 (interrupts disabled in trap handler)");
            end else begin
                $display("  [ERROR] CRMD.IE should be 0 in trap handler");
            end

            if (csr_crmd[1:0] == 2'b00) begin
                $display("  [OK] CRMD.PLV = 00 (kernel mode)");
            end else begin
                $display("  [ERROR] CRMD.PLV should be 00 in trap handler");
            end
        end
    end

    // Waveform dump for debugging
    initial begin
        $dumpfile("tb_soc_top.vcd");
        $dumpvars(0, tb_soc_top);
    end

endmodule
