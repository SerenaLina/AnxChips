module cpu (
    input  wire        clk,        // 系统时钟
    input  wire        rst_n,      // 异步复位（低电平有效）
    output reg  [15:0] led_data    // 16位 LED 输出数据总线
);

    // 假设输入时钟是 100MHz，我们设计一个 26 位的计数器
    // 100,000,000Hz / 2^26 ≈ 1.49Hz (LED 大约每秒闪烁 1.5 次)
    reg [25:0] count_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_reg <= 26'b0;
            led_data  <= 16'b0;
        end else begin
            count_reg <= count_reg + 1'b1;
            
            // 模拟 CPU 向 I/O 寄存器写入数据：
            // 将计数器的最高几位输出到 LED，实现流水灯或闪烁效果
            led_data[0]  <= count_reg[25];
            led_data[1]  <= ~count_reg[25]; // 反相闪烁
            led_data[2]  <= count_reg[24];
            led_data[3]  <= count_reg[23];
            led_data[15:4] <= 12'b0;        // 其余 LED 保持熄灭
        end
    end

endmodule