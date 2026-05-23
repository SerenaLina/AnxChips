// Simple 16-entry direct-mapped Branch Target Buffer
// Entry: {valid, tag[27:0], target[31:0]}   total 60 bits
// Index: pc[5:2]
module btb (
    input wire         clk,
    input wire         rst,
    // Lookup (combinational)
    input wire [31:0]  lookup_pc,
    output wire        hit,
    output wire [31:0] target,
    // Update (registered, from WB)
    input wire         update,
    input wire [31:0]  update_pc,
    input wire [31:0]  update_target
);
    reg [59:0] entries [0:15];  // 16 entries
    wire [3:0]  lookup_idx;
    wire [3:0] update_idx;

    assign lookup_idx  = lookup_pc[5:2];
    assign update_idx  = update_pc[5:2];

    wire        entry_valid;
    wire [27:0] entry_tag;
    wire [31:0] entry_target;

    assign {entry_valid, entry_tag, entry_target} = entries[lookup_idx];

    assign hit    = entry_valid && (entry_tag == lookup_pc[31:6]);
    assign target = entry_target;

    always @(posedge clk) begin
        if (rst) begin
            entries[0]  <= 60'd0;
            entries[1]  <= 60'd0;
            entries[2]  <= 60'd0;
            entries[3]  <= 60'd0;
            entries[4]  <= 60'd0;
            entries[5]  <= 60'd0;
            entries[6]  <= 60'd0;
            entries[7]  <= 60'd0;
            entries[8]  <= 60'd0;
            entries[9]  <= 60'd0;
            entries[10] <= 60'd0;
            entries[11] <= 60'd0;
            entries[12] <= 60'd0;
            entries[13] <= 60'd0;
            entries[14] <= 60'd0;
            entries[15] <= 60'd0;
        end else if (update) begin
            entries[update_idx] <= {1'b1, update_pc[31:6], update_target};
        end
    end
endmodule
