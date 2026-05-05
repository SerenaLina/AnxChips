`include "mycpu.h"

module trap_unit(
    input          clk,
    input          reset,
    // metadata bus from interrupter
    input  [`TRAP_INFO_WD-1:0] trap_info_bus,
    // CSR write interface
    output         csr_we,
    output [7:0]   csr_waddr,
    output [31:0]  csr_wdata,
    // CSR read interface
    input  [31:0]  csr_crmd_rdata,
    // exception entry address (configurable)
    output [31:0]  exc_entry_addr
);

// unpack trap_info_t structure
// trap_info_bus: {valid, epc[31:0]}
wire        trap_valid;
wire [31:0] epc;

assign trap_valid = trap_info_bus[32];
assign epc        = trap_info_bus[31:0];

// CSR register values for read-modify-write
reg [31:0] crmd_value;

// state machine for CSR update sequence
localparam IDLE = 2'b00;
localparam WRITE_PRMD = 2'b01;
localparam WRITE_CRMD = 2'b10;
localparam WRITE_ERA = 2'b11;

reg [1:0] state;
reg [1:0] next_state;

// sequential logic
always @(posedge clk) begin
    if (reset) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

// capture CRMD value when trap is detected (in IDLE state with trap_valid)
always @(posedge clk) begin
    if (reset) begin
        crmd_value <= 32'h0;
    end else if (trap_valid && state == IDLE) begin
        // capture current CRMD value from csr_register
        // CRMD[1:0]=PLV, CRMD[2]=IE
        crmd_value <= csr_crmd_rdata;
    end
end

// combinational logic for next state
always @(*) begin
    case (state)
        IDLE: begin
            if (trap_valid)
                next_state = WRITE_PRMD;
            else
                next_state = IDLE;
        end
        WRITE_PRMD: next_state = WRITE_CRMD;
        WRITE_CRMD: next_state = WRITE_ERA;
        WRITE_ERA:  next_state = IDLE;
        default:    next_state = IDLE;
    endcase
end

// CSR write control
reg         csr_we_reg;
reg  [7:0]  csr_waddr_reg;
reg  [31:0] csr_wdata_reg;

assign csr_we    = csr_we_reg;
assign csr_waddr = csr_waddr_reg;
assign csr_wdata = csr_wdata_reg;

// CSR write sequence
always @(posedge clk) begin
    if (reset) begin
        csr_we_reg   <= 1'b0;
        csr_waddr_reg <= 8'h00;
        csr_wdata_reg <= 32'h0;
    end else begin
        csr_we_reg <= 1'b0; // default
        case (state)
            WRITE_PRMD: begin
                // PRMD[1:0] = CRMD[1:0] (PPLV = PLV)
                // PRMD[2] = CRMD[2] (PIE = IE)
                csr_we_reg    <= 1'b1;
                csr_waddr_reg <= `CSR_PRMD;
                csr_wdata_reg <= {29'b0, crmd_value[2], crmd_value[1:0]};
            end
            WRITE_CRMD: begin
                // CRMD[1:0] = 0 (PLV = 0)
                // CRMD[2] = 0 (IE = 0)
                csr_we_reg    <= 1'b1;
                csr_waddr_reg <= `CSR_CRMD;
                csr_wdata_reg <= {29'b0, 1'b0, 2'b00};
            end
            WRITE_ERA: begin
                // ERA = epc (exception PC)
                csr_we_reg    <= 1'b1;
                csr_waddr_reg <= `CSR_ERA;
                csr_wdata_reg <= epc;
            end
            default: begin
                csr_we_reg   <= 1'b0;
                csr_waddr_reg <= 8'h00;
                csr_wdata_reg <= 32'h0;
            end
        endcase
    end
end

// exception entry address (configurable, currently empty/placeholder)
assign exc_entry_addr = 32'h0;

endmodule
