`timescale 1ns / 1ps

module xsim_smoke_dut #(
    parameter integer P_DONE_CYCLES = 4
)(
    // ========================================================
    // Clock and reset
    // ========================================================
    input  wire         C_gclk_100M_i,
    input  wire         R_gclk_100M_rst_i,

    // ========================================================
    // Control
    // ========================================================
    input  wire         start_i,
    output wire         done_o,
    output wire [7:0]   result_data_o
);

// ============================================================
// Local parameter
// ============================================================

localparam [7:0] LP_RESULT_VALUE = 8'hA5;

// ============================================================
// Internal signal
// ============================================================

reg        busy_r;
reg        done_r;
reg [7:0]  cycle_cnt_r;
reg [7:0]  result_data_r;

// ============================================================
// Sequential logic
// ============================================================

always @(posedge C_gclk_100M_i) begin
    if (R_gclk_100M_rst_i) begin
        busy_r        <= 1'b0;
        done_r        <= 1'b0;
        cycle_cnt_r   <= 8'd0;
        result_data_r <= 8'd0;
    end
    else begin
        done_r <= 1'b0;

        if (start_i && !busy_r) begin
            busy_r        <= 1'b1;
            cycle_cnt_r   <= 8'd0;
            result_data_r <= 8'd0;
        end
        else if (busy_r) begin
            if (cycle_cnt_r == (P_DONE_CYCLES - 1)) begin
                busy_r        <= 1'b0;
                done_r        <= 1'b1;
                result_data_r <= LP_RESULT_VALUE;
            end
            else begin
                cycle_cnt_r <= cycle_cnt_r + 1'b1;
            end
        end
    end
end

// ============================================================
// Output assignment
// ============================================================

assign done_o        = done_r;
assign result_data_o = result_data_r;

endmodule
