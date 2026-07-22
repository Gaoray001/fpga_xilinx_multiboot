`timescale 1ns / 1ps

module Top #(
    parameter integer PARAM_IMAGE_IS_APPLICATION = 1,
    parameter integer PARAM_CLK_FREQ_HZ          = 50_000_000,
    parameter integer PARAM_UART_BAUD            = 115_200,
    parameter [31:0]  PARAM_GOLDEN_ADDR          = 32'h0000_0000,
    parameter [31:0]  PARAM_APPLICATION_ADDR     = 32'h0080_0000
)(

    // Board clock and reset
    input  wire P_G_CLK,
    input  wire P_G_RST_N,

    // UART1
    output wire P_UART1_TX,
    input  wire P_UART1_RX,

    // Board indicator
    output wire P_led_out
); 

////////////////////////////////////////////////////////////////
// Local parameter
////////////////////////////////////////////////////////////////

localparam integer LPARAM_GOLDEN_LED_HALF_CYCLES = PARAM_CLK_FREQ_HZ / 2;
localparam integer LPARAM_APP_LED_HALF_CYCLES    = PARAM_CLK_FREQ_HZ / 8;
localparam integer LPARAM_LED_HALF_CYCLES        = PARAM_IMAGE_IS_APPLICATION ?
                                                   LPARAM_APP_LED_HALF_CYCLES :
                                                   LPARAM_GOLDEN_LED_HALF_CYCLES;
localparam integer LPARAM_LED_CNT_W              = $clog2(LPARAM_GOLDEN_LED_HALF_CYCLES);

////////////////////////////////////////////////////////////////
// Internal signal
////////////////////////////////////////////////////////////////

(* ASYNC_REG = "TRUE" *) reg [1:0] reset_sync_r;

wire        R_gclk_50M_rst_w;
wire        boot_req_valid_w;
wire        boot_req_ready_w;
wire [31:0] boot_req_addr_w;
wire        cmd_valid_w;
wire        cmd_ready_w;
wire [31:0] cmd_data_w;
wire        cmd_last_w;
wire        ctrl_idle_w;
wire        ctrl_busy_w;
wire        ctrl_done_w;
wire        ctrl_err_w;
wire [2:0]  ctrl_state_w;
wire [3:0]  ctrl_cmd_index_w;
wire [31:0] ctrl_target_addr_w;
wire        icap_csib_w;
wire        icap_rdwrb_w;
wire [31:0] icap_data_i_w;
wire [31:0] icap_data_o_w;

reg [LPARAM_LED_CNT_W-1:0] led_count_r;
reg                         led_state_r;

////////////////////////////////////////////////////////////////
// Reset synchronizer: asynchronous assert, synchronous release
////////////////////////////////////////////////////////////////

always @(posedge P_G_CLK or negedge P_G_RST_N) begin
    if (!P_G_RST_N) begin
        reset_sync_r <= 2'b11;
    end
    else begin
        reset_sync_r <= {reset_sync_r[0], 1'b0};
    end
end

assign R_gclk_50M_rst_w = reset_sync_r[1];

////////////////////////////////////////////////////////////////
// UART boot trigger
////////////////////////////////////////////////////////////////

    uart_boot_trigger #(
    .PARAM_CLK_FREQ_HZ                  (PARAM_CLK_FREQ_HZ         ),
    .PARAM_BAUD                         (PARAM_UART_BAUD           ),
    .PARAM_GOLDEN_ADDR                  (PARAM_GOLDEN_ADDR         ),
    .PARAM_APPLICATION_ADDR             (PARAM_APPLICATION_ADDR    ) 
    ) u_uart_boot_trigger (
    .C_gclk_50M_i                       (P_G_CLK                   ),
    .R_gclk_50M_rst_i                   (R_gclk_50M_rst_w          ),
    .uart_rx_i                          (P_UART1_RX                ),
    .uart_tx_o                          (P_UART1_TX                ),
    .req_valid_o                        (boot_req_valid_w          ),
    .req_ready_i                        (boot_req_ready_w          ),
    .req_addr_o                         (boot_req_addr_w           ) 
    );

////////////////////////////////////////////////////////////////
// Multiboot controller and ICAPE2 owner
////////////////////////////////////////////////////////////////

// The existing controller/wrapper port names retain their legacy 100M
// suffix; both modules operate synchronously from this board's 50 MHz clock.
    multiboot_ctrl u_multiboot_ctrl (
    .C_gclk_100M_i                      (P_G_CLK                   ),
    .R_gclk_100M_rst_i                  (R_gclk_50M_rst_w          ),
    .req_valid_i                        (boot_req_valid_w          ),
    .req_ready_o                        (boot_req_ready_w          ),
    .req_addr_i                         (boot_req_addr_w           ),
    .cmd_valid_o                        (cmd_valid_w               ),
    .cmd_ready_i                        (cmd_ready_w               ),
    .cmd_data_o                         (cmd_data_w                ),
    .cmd_last_o                         (cmd_last_w                ),
    .idle_o                             (ctrl_idle_w               ),
    .busy_o                             (ctrl_busy_w               ),
    .done_o                             (ctrl_done_w               ),
    .err_o                              (ctrl_err_w                ),
    .state_o                            (ctrl_state_w              ),
    .cmd_index_o                        (ctrl_cmd_index_w          ),
    .target_addr_o                      (ctrl_target_addr_w        ) 
    );

multiboot_icape2_wrapper u_multiboot_icape2_wrapper (
    .C_gclk_100M_i                      (P_G_CLK                   ),
    .R_gclk_100M_rst_i                  (R_gclk_50M_rst_w          ),
    .cmd_valid_i                        (cmd_valid_w               ),
    .cmd_ready_o                        (cmd_ready_w               ),
    .cmd_data_i                         (cmd_data_w                ),
    .icap_enable_i                      (1'b1                      ),
    .icap_csib_o                        (icap_csib_w               ),
    .icap_rdwrb_o                       (icap_rdwrb_w              ),
    .icap_data_i_o                      (icap_data_i_w             ),
    .icap_data_o_o                      (icap_data_o_w             ) 
);

////////////////////////////////////////////////////////////////
// Image identity LED: Golden 1 Hz, Application 4 Hz
////////////////////////////////////////////////////////////////

always @(posedge P_G_CLK) begin
    if (R_gclk_50M_rst_w) begin
        led_count_r <= {LPARAM_LED_CNT_W{1'b0}};
        led_state_r <= 1'b0;
    end
    else begin
        if (led_count_r == (LPARAM_LED_HALF_CYCLES - 1)) begin
            led_count_r <= {LPARAM_LED_CNT_W{1'b0}};
            led_state_r <= !led_state_r;
        end
        else begin
            led_count_r <= led_count_r + 1'b1;
        end
    end
end

assign P_led_out = led_state_r;

endmodule
