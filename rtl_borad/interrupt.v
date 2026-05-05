`include "mycpu.h"

module interrupt(
    input  wire [31:0] nextpc,
    output wire        int_stall_req,
    // metadata bus to trap_unit
    output wire [`TRAP_INFO_WD-1:0] trap_info_bus
);

// detect trap condition
wire trap_valid;
assign trap_valid = (nextpc[1:0] != 2'b00);

// int_stall_req is same as trap_valid
assign int_stall_req = trap_valid;

// pack trap_info_t structure
// trap_info_t:
//   - valid: 1 bit
//   - epc: 32 bits (PC value when trap occurs)
assign trap_info_bus = {trap_valid, nextpc};

endmodule
