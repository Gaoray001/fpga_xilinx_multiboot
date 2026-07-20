`timescale 1ns / 1ps

module uart_boot_trigger #(
    parameter integer PARAM_CLK_FREQ_HZ        = 50_000_000,
    parameter integer PARAM_BAUD               = 115_200,
    parameter integer PARAM_CMD_TIMEOUT_CYCLES = PARAM_CLK_FREQ_HZ / 2,
    parameter [31:0]  PARAM_GOLDEN_ADDR        = 32'h0000_0000,
    parameter [31:0]  PARAM_APPLICATION_ADDR   = 32'h0080_0000
)(

    // Clock and reset
    input  wire         C_gclk_50M_i,
    input  wire         R_gclk_50M_rst_i,

    // UART pins
    input  wire         uart_rx_i,
    output wire         uart_tx_o,

    // Multiboot request
    output wire         req_valid_o,
    input  wire         req_ready_i,
    output wire [31:0]  req_addr_o
);

////////////////////////////////////////////////////////////////
// Local parameter
////////////////////////////////////////////////////////////////

localparam [4:0] ST_CMD_B       = 5'd0;
localparam [4:0] ST_CMD_O1      = 5'd1;
localparam [4:0] ST_CMD_O2      = 5'd2;
localparam [4:0] ST_CMD_T       = 5'd3;
localparam [4:0] ST_CMD_SPACE   = 5'd4;
localparam [4:0] ST_CMD_TARGET  = 5'd5;
localparam [4:0] ST_CMD_APP_P1  = 5'd6;
localparam [4:0] ST_CMD_APP_P2  = 5'd7;
localparam [4:0] ST_CMD_APP_CR  = 5'd8;
localparam [4:0] ST_CMD_APP_LF  = 5'd9;
localparam [4:0] ST_CMD_G_O     = 5'd10;
localparam [4:0] ST_CMD_G_L     = 5'd11;
localparam [4:0] ST_CMD_G_D     = 5'd12;
localparam [4:0] ST_CMD_G_E     = 5'd13;
localparam [4:0] ST_CMD_G_N     = 5'd14;
localparam [4:0] ST_CMD_G_CR    = 5'd15;
localparam [4:0] ST_CMD_G_LF    = 5'd16;

localparam [7:0] LPARAM_ASCII_B     = 8'h42;
localparam [7:0] LPARAM_ASCII_O     = 8'h4F;
localparam [7:0] LPARAM_ASCII_T     = 8'h54;
localparam [7:0] LPARAM_ASCII_SPACE = 8'h20;
localparam [7:0] LPARAM_ASCII_A     = 8'h41;
localparam [7:0] LPARAM_ASCII_P     = 8'h50;
localparam [7:0] LPARAM_ASCII_G     = 8'h47;
localparam [7:0] LPARAM_ASCII_L     = 8'h4C;
localparam [7:0] LPARAM_ASCII_D     = 8'h44;
localparam [7:0] LPARAM_ASCII_E     = 8'h45;
localparam [7:0] LPARAM_ASCII_N     = 8'h4E;
localparam [7:0] LPARAM_ASCII_CR    = 8'h0D;
localparam [7:0] LPARAM_ASCII_LF    = 8'h0A;
localparam [7:0] LPARAM_UART_ACK    = 8'h06;

localparam integer LPARAM_TIMEOUT_CNT_W = $clog2(PARAM_CMD_TIMEOUT_CYCLES);

////////////////////////////////////////////////////////////////
// Internal signal
////////////////////////////////////////////////////////////////

wire       rx_data_valid_w;
wire [7:0] rx_data_w;
wire       rx_frame_err_w;
wire       tx_done_w;
wire       req_fire_w;

reg [4:0]                        cmd_state_r;
reg [LPARAM_TIMEOUT_CNT_W-1:0]   cmd_timeout_count_r;
reg                              tx_start_r;
reg                              request_pending_r;
reg                              req_valid_r;
reg [31:0]                       req_addr_r;

////////////////////////////////////////////////////////////////
// UART byte receiver/transmitter
////////////////////////////////////////////////////////////////

uart_rx_byte #(
    .PARAM_CLK_FREQ_HZ (PARAM_CLK_FREQ_HZ),
    .PARAM_BAUD        (PARAM_BAUD)
) u_uart_rx_byte (
    .C_gclk_50M_i      (C_gclk_50M_i),
    .R_gclk_50M_rst_i  (R_gclk_50M_rst_i),
    .rx_i              (uart_rx_i),
    .data_valid_o      (rx_data_valid_w),
    .data_o            (rx_data_w),
    .frame_err_o       (rx_frame_err_w)
);

uart_tx_byte #(
    .PARAM_CLK_FREQ_HZ (PARAM_CLK_FREQ_HZ),
    .PARAM_BAUD        (PARAM_BAUD)
) u_uart_tx_byte (
    .C_gclk_50M_i      (C_gclk_50M_i),
    .R_gclk_50M_rst_i  (R_gclk_50M_rst_i),
    .start_i           (tx_start_r),
    .data_i            (LPARAM_UART_ACK),
    .tx_o              (uart_tx_o),
    .done_o            (tx_done_w)
);

////////////////////////////////////////////////////////////////
// Command parser and request handshake
////////////////////////////////////////////////////////////////

assign req_fire_w = req_valid_r && req_ready_i;

always @(posedge C_gclk_50M_i) begin
    if (R_gclk_50M_rst_i) begin
        cmd_state_r         <= ST_CMD_B;
        cmd_timeout_count_r <= {LPARAM_TIMEOUT_CNT_W{1'b0}};
        tx_start_r          <= 1'b0;
        request_pending_r   <= 1'b0;
        req_valid_r         <= 1'b0;
        req_addr_r          <= PARAM_GOLDEN_ADDR;
    end
    else begin
        tx_start_r <= 1'b0;

        if (req_fire_w) begin
            request_pending_r <= 1'b0;
            req_valid_r       <= 1'b0;
        end
        else if (tx_done_w && request_pending_r) begin
            req_valid_r <= 1'b1;
        end

        if (rx_frame_err_w) begin
            cmd_state_r         <= ST_CMD_B;
            cmd_timeout_count_r <= {LPARAM_TIMEOUT_CNT_W{1'b0}};
        end
        else if (rx_data_valid_w) begin
            cmd_timeout_count_r <= {LPARAM_TIMEOUT_CNT_W{1'b0}};
            if (request_pending_r || req_valid_r) begin
                cmd_state_r <= ST_CMD_B;
            end
            else begin
                case (cmd_state_r)
                    ST_CMD_B: begin
                        cmd_state_r <= (rx_data_w == LPARAM_ASCII_B) ? ST_CMD_O1 : ST_CMD_B;
                    end

                    ST_CMD_O1: begin
                        cmd_state_r <= (rx_data_w == LPARAM_ASCII_O) ? ST_CMD_O2 : ST_CMD_B;
                    end

                    ST_CMD_O2: begin
                        cmd_state_r <= (rx_data_w == LPARAM_ASCII_O) ? ST_CMD_T : ST_CMD_B;
                    end

                    ST_CMD_T: begin
                        cmd_state_r <= (rx_data_w == LPARAM_ASCII_T) ? ST_CMD_SPACE : ST_CMD_B;
                    end

                    ST_CMD_SPACE: begin
                        cmd_state_r <= (rx_data_w == LPARAM_ASCII_SPACE) ? ST_CMD_TARGET : ST_CMD_B;
                    end

                    ST_CMD_TARGET: begin
                        if (rx_data_w == LPARAM_ASCII_A) begin
                            cmd_state_r <= ST_CMD_APP_P1;
                        end
                        else if (rx_data_w == LPARAM_ASCII_G) begin
                            cmd_state_r <= ST_CMD_G_O;
                        end
                        else begin
                            cmd_state_r <= ST_CMD_B;
                        end
                    end

                    ST_CMD_APP_P1: begin
                        cmd_state_r <= (rx_data_w == LPARAM_ASCII_P) ? ST_CMD_APP_P2 : ST_CMD_B;
                    end

                    ST_CMD_APP_P2: begin
                        cmd_state_r <= (rx_data_w == LPARAM_ASCII_P) ? ST_CMD_APP_CR : ST_CMD_B;
                    end

                    ST_CMD_APP_CR: begin
                        cmd_state_r <= (rx_data_w == LPARAM_ASCII_CR) ? ST_CMD_APP_LF : ST_CMD_B;
                    end

                    ST_CMD_APP_LF: begin
                        cmd_state_r <= ST_CMD_B;
                        if (rx_data_w == LPARAM_ASCII_LF) begin
                            req_addr_r        <= PARAM_APPLICATION_ADDR;
                            request_pending_r <= 1'b1;
                            tx_start_r        <= 1'b1;
                        end
                    end

                    ST_CMD_G_O: begin
                        cmd_state_r <= (rx_data_w == LPARAM_ASCII_O) ? ST_CMD_G_L : ST_CMD_B;
                    end

                    ST_CMD_G_L: begin
                        cmd_state_r <= (rx_data_w == LPARAM_ASCII_L) ? ST_CMD_G_D : ST_CMD_B;
                    end

                    ST_CMD_G_D: begin
                        cmd_state_r <= (rx_data_w == LPARAM_ASCII_D) ? ST_CMD_G_E : ST_CMD_B;
                    end

                    ST_CMD_G_E: begin
                        cmd_state_r <= (rx_data_w == LPARAM_ASCII_E) ? ST_CMD_G_N : ST_CMD_B;
                    end

                    ST_CMD_G_N: begin
                        cmd_state_r <= (rx_data_w == LPARAM_ASCII_N) ? ST_CMD_G_CR : ST_CMD_B;
                    end

                    ST_CMD_G_CR: begin
                        cmd_state_r <= (rx_data_w == LPARAM_ASCII_CR) ? ST_CMD_G_LF : ST_CMD_B;
                    end

                    ST_CMD_G_LF: begin
                        cmd_state_r <= ST_CMD_B;
                        if (rx_data_w == LPARAM_ASCII_LF) begin
                            req_addr_r        <= PARAM_GOLDEN_ADDR;
                            request_pending_r <= 1'b1;
                            tx_start_r        <= 1'b1;
                        end
                    end

                    default: begin
                        cmd_state_r <= ST_CMD_B;
                    end
                endcase
            end
        end
        else if (cmd_state_r != ST_CMD_B) begin
            if (cmd_timeout_count_r == (PARAM_CMD_TIMEOUT_CYCLES - 1)) begin
                cmd_state_r         <= ST_CMD_B;
                cmd_timeout_count_r <= {LPARAM_TIMEOUT_CNT_W{1'b0}};
            end
            else begin
                cmd_timeout_count_r <= cmd_timeout_count_r + 1'b1;
            end
        end
        else begin
            cmd_timeout_count_r <= {LPARAM_TIMEOUT_CNT_W{1'b0}};
        end
    end
end

assign req_valid_o = req_valid_r;
assign req_addr_o  = req_addr_r;

endmodule

module uart_rx_byte #(
    parameter integer PARAM_CLK_FREQ_HZ = 50_000_000,
    parameter integer PARAM_BAUD        = 115_200
)(

    input  wire         C_gclk_50M_i,
    input  wire         R_gclk_50M_rst_i,
    input  wire         rx_i,
    output wire         data_valid_o,
    output wire [7:0]   data_o,
    output wire         frame_err_o
);

localparam integer LPARAM_CLKS_PER_BIT = (PARAM_CLK_FREQ_HZ + (PARAM_BAUD / 2)) / PARAM_BAUD;
localparam integer LPARAM_HALF_BIT     = LPARAM_CLKS_PER_BIT / 2;
localparam integer LPARAM_BAUD_CNT_W   = $clog2(LPARAM_CLKS_PER_BIT);

localparam [1:0] ST_IDLE  = 2'd0;
localparam [1:0] ST_START = 2'd1;
localparam [1:0] ST_DATA  = 2'd2;
localparam [1:0] ST_STOP  = 2'd3;

(* ASYNC_REG = "TRUE" *) reg rx_sync1_r;
(* ASYNC_REG = "TRUE" *) reg rx_sync2_r;

reg [1:0]                     state_r;
reg [LPARAM_BAUD_CNT_W-1:0]   baud_count_r;
reg [2:0]                     bit_index_r;
reg [7:0]                     data_r;
reg                           data_valid_r;
reg                           frame_err_r;

always @(posedge C_gclk_50M_i) begin
    if (R_gclk_50M_rst_i) begin
        rx_sync1_r <= 1'b1;
        rx_sync2_r <= 1'b1;
    end
    else begin
        rx_sync1_r <= rx_i;
        rx_sync2_r <= rx_sync1_r;
    end
end

always @(posedge C_gclk_50M_i) begin
    if (R_gclk_50M_rst_i) begin
        state_r      <= ST_IDLE;
        baud_count_r <= {LPARAM_BAUD_CNT_W{1'b0}};
        bit_index_r  <= 3'd0;
        data_r       <= 8'd0;
        data_valid_r <= 1'b0;
        frame_err_r  <= 1'b0;
    end
    else begin
        data_valid_r <= 1'b0;
        frame_err_r  <= 1'b0;

        case (state_r)
            ST_IDLE: begin
                baud_count_r <= {LPARAM_BAUD_CNT_W{1'b0}};
                bit_index_r  <= 3'd0;
                if (!rx_sync2_r) begin
                    state_r <= ST_START;
                end
            end

            ST_START: begin
                if (baud_count_r == (LPARAM_HALF_BIT - 1)) begin
                    baud_count_r <= {LPARAM_BAUD_CNT_W{1'b0}};
                    if (!rx_sync2_r) begin
                        state_r <= ST_DATA;
                    end
                    else begin
                        state_r <= ST_IDLE;
                    end
                end
                else begin
                    baud_count_r <= baud_count_r + 1'b1;
                end
            end

            ST_DATA: begin
                if (baud_count_r == (LPARAM_CLKS_PER_BIT - 1)) begin
                    baud_count_r         <= {LPARAM_BAUD_CNT_W{1'b0}};
                    data_r[bit_index_r] <= rx_sync2_r;
                    if (bit_index_r == 3'd7) begin
                        bit_index_r <= 3'd0;
                        state_r     <= ST_STOP;
                    end
                    else begin
                        bit_index_r <= bit_index_r + 1'b1;
                    end
                end
                else begin
                    baud_count_r <= baud_count_r + 1'b1;
                end
            end

            ST_STOP: begin
                if (baud_count_r == (LPARAM_CLKS_PER_BIT - 1)) begin
                    baud_count_r <= {LPARAM_BAUD_CNT_W{1'b0}};
                    state_r      <= ST_IDLE;
                    if (rx_sync2_r) begin
                        data_valid_r <= 1'b1;
                    end
                    else begin
                        frame_err_r <= 1'b1;
                    end
                end
                else begin
                    baud_count_r <= baud_count_r + 1'b1;
                end
            end

            default: begin
                state_r <= ST_IDLE;
            end
        endcase
    end
end

assign data_valid_o = data_valid_r;
assign data_o       = data_r;
assign frame_err_o  = frame_err_r;

endmodule

module uart_tx_byte #(
    parameter integer PARAM_CLK_FREQ_HZ = 50_000_000,
    parameter integer PARAM_BAUD        = 115_200
)(

    input  wire         C_gclk_50M_i,
    input  wire         R_gclk_50M_rst_i,
    input  wire         start_i,
    input  wire [7:0]   data_i,
    output wire         tx_o,
    output wire         done_o
);

localparam integer LPARAM_CLKS_PER_BIT = (PARAM_CLK_FREQ_HZ + (PARAM_BAUD / 2)) / PARAM_BAUD;
localparam integer LPARAM_BAUD_CNT_W   = $clog2(LPARAM_CLKS_PER_BIT);

localparam [1:0] ST_IDLE  = 2'd0;
localparam [1:0] ST_START = 2'd1;
localparam [1:0] ST_DATA  = 2'd2;
localparam [1:0] ST_STOP  = 2'd3;

reg [1:0]                   state_r;
reg [LPARAM_BAUD_CNT_W-1:0] baud_count_r;
reg [2:0]                   bit_index_r;
reg [7:0]                   data_r;
reg                         tx_r;
reg                         done_r;

always @(posedge C_gclk_50M_i) begin
    if (R_gclk_50M_rst_i) begin
        state_r      <= ST_IDLE;
        baud_count_r <= {LPARAM_BAUD_CNT_W{1'b0}};
        bit_index_r  <= 3'd0;
        data_r       <= 8'd0;
        tx_r         <= 1'b1;
        done_r       <= 1'b0;
    end
    else begin
        done_r <= 1'b0;

        case (state_r)
            ST_IDLE: begin
                baud_count_r <= {LPARAM_BAUD_CNT_W{1'b0}};
                bit_index_r  <= 3'd0;
                tx_r         <= 1'b1;
                if (start_i) begin
                    data_r  <= data_i;
                    tx_r    <= 1'b0;
                    state_r <= ST_START;
                end
            end

            ST_START: begin
                if (baud_count_r == (LPARAM_CLKS_PER_BIT - 1)) begin
                    baud_count_r <= {LPARAM_BAUD_CNT_W{1'b0}};
                    tx_r         <= data_r[0];
                    state_r      <= ST_DATA;
                end
                else begin
                    baud_count_r <= baud_count_r + 1'b1;
                end
            end

            ST_DATA: begin
                if (baud_count_r == (LPARAM_CLKS_PER_BIT - 1)) begin
                    baud_count_r <= {LPARAM_BAUD_CNT_W{1'b0}};
                    if (bit_index_r == 3'd7) begin
                        bit_index_r <= 3'd0;
                        tx_r        <= 1'b1;
                        state_r     <= ST_STOP;
                    end
                    else begin
                        bit_index_r <= bit_index_r + 1'b1;
                        tx_r        <= data_r[bit_index_r + 1'b1];
                    end
                end
                else begin
                    baud_count_r <= baud_count_r + 1'b1;
                end
            end

            ST_STOP: begin
                if (baud_count_r == (LPARAM_CLKS_PER_BIT - 1)) begin
                    baud_count_r <= {LPARAM_BAUD_CNT_W{1'b0}};
                    tx_r         <= 1'b1;
                    done_r       <= 1'b1;
                    state_r      <= ST_IDLE;
                end
                else begin
                    baud_count_r <= baud_count_r + 1'b1;
                end
            end

            default: begin
                state_r <= ST_IDLE;
                tx_r    <= 1'b1;
            end
        endcase
    end
end

assign tx_o   = tx_r;
assign done_o = done_r;

endmodule
