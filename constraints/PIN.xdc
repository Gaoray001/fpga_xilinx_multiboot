set_property IOSTANDARD LVCMOS33 [get_ports P_G_CLK]
set_property IOSTANDARD LVCMOS33 [get_ports P_G_RST_N]

set_property PACKAGE_PIN W19 [get_ports P_G_CLK]
set_property PACKAGE_PIN N15 [get_ports P_G_RST_N]

#led灯
set_property IOSTANDARD LVCMOS33 [get_ports P_led_out]
set_property PACKAGE_PIN M21 [get_ports P_led_out]

#4线spi模式
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]

