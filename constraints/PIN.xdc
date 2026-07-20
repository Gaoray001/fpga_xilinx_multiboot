set_property IOSTANDARD LVCMOS33 [get_ports P_G_CLK]
set_property IOSTANDARD LVCMOS33 [get_ports P_G_RST_N]

set_property PACKAGE_PIN W19 [get_ports P_G_CLK]
set_property PACKAGE_PIN N15 [get_ports P_G_RST_N]
create_clock -name C_gclk_50M -period 20.000 [get_ports P_G_CLK]

# UART1
set_property IOSTANDARD LVCMOS33 [get_ports {P_UART1_TX P_UART1_RX}]
set_property PACKAGE_PIN N17 [get_ports P_UART1_TX]
set_property PACKAGE_PIN P17 [get_ports P_UART1_RX]

# LED
set_property IOSTANDARD LVCMOS33 [get_ports P_led_out]
set_property PACKAGE_PIN M21 [get_ports P_led_out]

# Master SPI x4 configuration
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 12 [current_design]
set_property BITSTREAM.CONFIG.CONFIGFALLBACK ENABLE [current_design]
set_property BITSTREAM.CONFIG.TIMER_CFG 0x00050000 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS FALSE [current_design]

