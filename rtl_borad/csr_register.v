`include "mycpu.h"

module csr_register(
    input          clk,
    input          reset,
    
    // write interface from trap_unit
    input          csr_we,
    input  [7:0]   csr_waddr,
    input  [31:0]  csr_wdata,
    
    // read interface (for future use)
    input  [7:0]   csr_raddr,
    output [31:0]  csr_rdata,
    
    // direct access to CSR values
    output [31:0]  csr_crmd,
    output [31:0]  csr_prmd,
    output [31:0]  csr_era,
    output [31:0]  csr_badv
);

// CSR registers
reg [31:0] CRMD;  // Current Mode: [1:0]=PLV, [2]=IE
reg [31:0] PRMD;  // Previous Mode: [1:0]=PPLV, [2]=PIE
reg [31:0] ERA;   // Exception Return Address
reg [31:0] BADV;  // Bad Virtual Address

// write logic
always @(posedge clk) begin
    if (reset) begin
        CRMD <= 32'h00000000;
        PRMD <= 32'h00000000;
        ERA  <= 32'h00000000;
        BADV <= 32'h00000000;
    end
    else if (csr_we) begin
        case (csr_waddr)
            `CSR_CRMD: CRMD <= csr_wdata;
            `CSR_PRMD: PRMD <= csr_wdata;
            `CSR_ERA:  ERA  <= csr_wdata;
            `CSR_BADV: BADV <= csr_wdata;
            default: ;
        endcase
    end
end

// read logic
assign csr_rdata = (csr_raddr == `CSR_CRMD) ? CRMD :
                   (csr_raddr == `CSR_PRMD) ? PRMD :
                   (csr_raddr == `CSR_ERA)  ? ERA  :
                   (csr_raddr == `CSR_BADV) ? BADV :
                                              32'h00000000;

// direct output
assign csr_crmd  = CRMD;
assign csr_prmd  = PRMD;
assign csr_era   = ERA;
assign csr_badv  = BADV;

endmodule
