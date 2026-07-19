`timescale 1ns / 1ps

module multiboot_ctrl #(
    parameter integer P_ADDR_W = 32,
    parameter integer P_CMD_W  = 32
)(
    // ========================================================
    // Clock and reset
    // ========================================================
    input  wire                  C_gclk_100M_i,
    input  wire                  R_gclk_100M_rst_i,

    // ========================================================
    // Multiboot request
    // ========================================================
    input  wire                  req_valid_i,
    output wire                  req_ready_o,
    input  wire [P_ADDR_W-1:0]   req_addr_i,

    // ========================================================
    // Abstract ICAP command stream
    // ========================================================
    output wire                  cmd_valid_o,
    input  wire                  cmd_ready_i,
    output wire [P_CMD_W-1:0]    cmd_data_o,
    output wire                  cmd_last_o,

    // ========================================================
    // Status
    // ========================================================
    output wire                  idle_o,
    output wire                  busy_o,
    output wire                  done_o, 
    output wire                  err_o,
    output wire [2:0]            state_o,
    output wire [3:0]            cmd_index_o,
    output wire [P_ADDR_W-1:0]   target_addr_o
);

// ============================================================
// Local parameter
// ============================================================

localparam [2:0] ST_IDLE  = 3'd0;
localparam [2:0] ST_SEND  = 3'd1;
localparam [2:0] ST_DONE  = 3'd2;
localparam [2:0] ST_ERROR = 3'd3;

localparam [3:0] LP_CMD_DUMMY_IDX        = 4'd0;
localparam [3:0] LP_CMD_SYNC_IDX         = 4'd1;
localparam [3:0] LP_CMD_NOOP0_IDX        = 4'd2;
localparam [3:0] LP_CMD_WRITE_WBSTAR_IDX = 4'd3;
localparam [3:0] LP_CMD_TARGET_ADDR_IDX  = 4'd4;
localparam [3:0] LP_CMD_WRITE_CMD_IDX    = 4'd5;
localparam [3:0] LP_CMD_IPROG_IDX        = 4'd6;
localparam [3:0] LP_CMD_NOOP1_IDX        = 4'd7;
localparam [3:0] LP_CMD_LAST_IDX         = LP_CMD_NOOP1_IDX;

localparam [P_CMD_W-1:0] LP_CMD_DUMMY        = 32'hFFFFFFFF;
localparam [P_CMD_W-1:0] LP_CMD_SYNC         = 32'hAA995566;
localparam [P_CMD_W-1:0] LP_CMD_NOOP         = 32'h20000000;
localparam [P_CMD_W-1:0] LP_CMD_WRITE_WBSTAR = 32'h30020001;
localparam [P_CMD_W-1:0] LP_CMD_WRITE_CMD    = 32'h30008001;
localparam [P_CMD_W-1:0] LP_CMD_IPROG        = 32'h0000000F;

// ============================================================
// Internal signal
// ============================================================

wire req_fire_w;
wire cmd_fire_w;
wire cmd_last_w;

reg [2:0]          state_r;
reg [2:0]          state_n;
reg [3:0]          cmd_index_r;
reg [P_ADDR_W-1:0] target_addr_r;
reg [P_CMD_W-1:0]  cmd_data_r;

// ============================================================
// Handshake
// ============================================================

assign req_fire_w = req_valid_i && req_ready_o;
assign cmd_fire_w = cmd_valid_o && cmd_ready_i;
assign cmd_last_w = cmd_index_r == LP_CMD_LAST_IDX;

// ============================================================
// FSM next-state logic
// ============================================================

always @(*) begin
    state_n = state_r;

    case (state_r)
        ST_IDLE: begin
            if (req_fire_w) begin
                state_n = ST_SEND;
            end
        end

        ST_SEND: begin
            if (cmd_fire_w && cmd_last_w) begin
                state_n = ST_DONE;
            end
        end

        ST_DONE: begin
            state_n = ST_IDLE;
        end

        ST_ERROR: begin
            state_n = ST_ERROR;
        end

        default: begin
            state_n = ST_ERROR;
        end
    endcase
end

// ============================================================
// Command mux
// ============================================================

always @(*) begin
    case (cmd_index_r)
        LP_CMD_DUMMY_IDX: begin
            cmd_data_r = LP_CMD_DUMMY;
        end

        LP_CMD_SYNC_IDX: begin
            cmd_data_r = LP_CMD_SYNC;
        end

        LP_CMD_NOOP0_IDX: begin
            cmd_data_r = LP_CMD_NOOP;
        end

        LP_CMD_WRITE_WBSTAR_IDX: begin
            cmd_data_r = LP_CMD_WRITE_WBSTAR;
        end

        LP_CMD_TARGET_ADDR_IDX: begin
            cmd_data_r = target_addr_r[P_CMD_W-1:0];
        end

        LP_CMD_WRITE_CMD_IDX: begin
            cmd_data_r = LP_CMD_WRITE_CMD;
        end

        LP_CMD_IPROG_IDX: begin
            cmd_data_r = LP_CMD_IPROG;
        end

        LP_CMD_NOOP1_IDX: begin
            cmd_data_r = LP_CMD_NOOP;
        end

        default: begin
            cmd_data_r = {P_CMD_W{1'b0}};
        end
    endcase
end

// ============================================================
// Sequential logic
// ============================================================

always @(posedge C_gclk_100M_i) begin
    if (R_gclk_100M_rst_i) begin
        state_r       <= ST_IDLE;
        cmd_index_r   <= 4'd0;
        target_addr_r <= {P_ADDR_W{1'b0}};
    end
    else begin
        state_r <= state_n;

        if (req_fire_w) begin
            target_addr_r <= req_addr_i;
            cmd_index_r   <= 4'd0;
        end
        else if (cmd_fire_w) begin
            if (cmd_last_w) begin
                cmd_index_r <= 4'd0;
            end
            else begin
                cmd_index_r <= cmd_index_r + 1'b1;
            end
        end
        else if (state_r == ST_DONE) begin
            cmd_index_r <= 4'd0;
        end
    end
end

// ============================================================
// Output assignment
// ============================================================

assign req_ready_o   = state_r == ST_IDLE;
assign cmd_valid_o   = state_r == ST_SEND;
assign cmd_data_o    = cmd_data_r;
assign cmd_last_o    = cmd_valid_o && cmd_last_w;

assign idle_o        = state_r == ST_IDLE;
assign busy_o        = state_r == ST_SEND;
assign done_o        = state_r == ST_DONE;
assign err_o         = state_r == ST_ERROR;
assign state_o       = state_r;
assign cmd_index_o   = cmd_index_r;
assign target_addr_o = target_addr_r;

endmodule
