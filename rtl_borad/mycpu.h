`ifndef MYCPU_H
    `define MYCPU_H

    `define BR_BUS_WD       34
    `define FS_TO_DS_BUS_WD 64
    `define DS_TO_ES_BUS_WD 207
    `define ES_TO_MS_BUS_WD 273
    `define MS_TO_WS_BUS_WD 232
    `define WS_TO_RF_BUS_WD 135
    
    // Instruction bus width: 46 instructions
    `define INST_BUS_WD     46

    // CSR addresses
    `define CSR_CRMD        8'h00
    `define CSR_PRMD        8'h01
    `define CSR_ERA         8'h06
    `define CSR_BADV        8'h07

    // Trap info bus width: valid(1) + epc(32) = 33 bits
    `define TRAP_INFO_WD    33

`endif
