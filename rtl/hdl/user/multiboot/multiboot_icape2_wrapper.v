`timescale 1ns / 1ps

module multiboot_icape2_wrapper (
    // ========================================================
    // Clock and reset
    // ========================================================
    input  wire          C_gclk_100M_i,
    input  wire          R_gclk_100M_rst_i,

    // ========================================================
    // Abstract command stream
    // ========================================================
    input  wire          cmd_valid_i,
    output wire          cmd_ready_o,
    input  wire [31:0]   cmd_data_i,

    // ========================================================
    // ICAP access control and observation
    // ========================================================
    input  wire          icap_enable_i,
    output wire          icap_csib_o,
    output wire          icap_rdwrb_o,
    output wire [31:0]   icap_data_i_o,
    output wire [31:0]   icap_data_o_o
);

// ============================================================
// Internal signal
// ============================================================

wire        cmd_fire_w;
wire [31:0] icap_data_w;
wire [31:0] icap_read_data_w;

// ============================================================
// ICAP data bit order
// ============================================================

function [7:0] bit_reverse_byte;
    input [7:0] data_i;
    begin
        bit_reverse_byte = {
            data_i[0], data_i[1], data_i[2], data_i[3],
            data_i[4], data_i[5], data_i[6], data_i[7]
        };
    end
endfunction

assign icap_data_w = {
    bit_reverse_byte(cmd_data_i[31:24]),
    bit_reverse_byte(cmd_data_i[23:16]),
    bit_reverse_byte(cmd_data_i[15:8]),
    bit_reverse_byte(cmd_data_i[7:0])
};

// ICAPE2 has no ready output. The enable input lets the owner delay or
// temporarily pause writes while preserving valid/ready stream semantics.
assign cmd_ready_o = icap_enable_i && !R_gclk_100M_rst_i;
assign cmd_fire_w  = cmd_valid_i && cmd_ready_o;

assign icap_csib_o   = !cmd_fire_w;
assign icap_rdwrb_o  = 1'b0;
assign icap_data_i_o = icap_data_w;
assign icap_data_o_o = icap_read_data_w;

// ============================================================
// 7 Series / Zynq-7000 internal configuration access port
// ============================================================

    ICAPE2 #(
    .ICAP_WIDTH                         ("X32"                     ),//数据总线位宽
    .SIM_CFG_FILE_NAME                  ("NONE"                    ) 
    ) u_icape2 (
    .O                                  (icap_read_data_w          ),//读数据总线X32bit
    .CLK                                (C_gclk_100M_i             ),
    .CSIB                               (icap_csib_o               ),//片选使能
    .I                                  (icap_data_w               ),//写数据总线X32bit
    .RDWRB                              (icap_rdwrb_o              ) //读/写选择
    );

endmodule
