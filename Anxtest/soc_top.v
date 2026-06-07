module soc_top (
    input  wire [15:0] clk_candidates,   // 已经找对的真时钟引脚
    output wire [15:0] led    // 16个物理 LED 引脚
);

    // 实例化你的 VIO 
    // 对应你截图里的名字，把它们依次赋给 led[0] 到 led[15]
    wire master_clk;
    assign master_clk = ^clk_candidates;
    vio_0 u_vio (
        .clk          (master_clk),
        .probe_out0   (led[0]),  // 对应你截图第一行的 led_OBUF[0:0]
        .probe_out1   (led[1]),
        .probe_out2   (led[2]),
        .probe_out3   (led[3]),
        .probe_out4   (led[4]),
        .probe_out5   (led[5]),
        .probe_out6   (led[6]),
        .probe_out7   (led[7]),
        .probe_out8   (led[8]),
        .probe_out9   (led[9]),
        .probe_out10  (led[10]),
        .probe_out11  (led[11]),
        .probe_out12  (led[12]),
        .probe_out13  (led[13]),
        .probe_out14  (led[14]),
        .probe_out15  (led[15])
    );

endmodule