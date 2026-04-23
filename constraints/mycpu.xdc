# mycpu constraints file
# 请根据您的实际FPGA板子修改引脚分配

# 时钟约束 - 需要根据实际板子修改
# set_property PACKAGE_PIN Y9 [get_ports clk]
# set_property IOSTANDARD LVCMOS33 [get_ports clk]
# create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]

# 复位引脚
# set_property PACKAGE_PIN P16 [get_ports resetn]
# set_property IOSTANDARD LVCMOS33 [get_ports resetn]

# 如果暂时不需要实际上板，可以使用以下命令禁用I/O检查
# set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
# set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
# set_property SEVERITY {Warning} [get_drc_checks RTSTAT-1]
