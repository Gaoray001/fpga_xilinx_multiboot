`timescale 1ns / 1ps

module tb_xsim_smoke;

// ============================================================
// Local parameter
// ============================================================

localparam integer LP_CLK_HALF_NS = 5;
localparam integer LP_TIMEOUT     = 16;

// ============================================================
// Testbench signal
// ============================================================

reg        C_gclk_100M_r;
reg        R_gclk_100M_rst_r;
reg        start_r;
wire       done_w;
wire [7:0] result_data_w;

integer fail_count;
integer timeout_count;

// ============================================================
// Clock
// ============================================================

initial begin
    C_gclk_100M_r = 1'b0;
end

always begin
    #LP_CLK_HALF_NS C_gclk_100M_r = ~C_gclk_100M_r;
end

// ============================================================
// DUT
// ============================================================

xsim_smoke_dut u_xsim_smoke_dut (
    // ========================================================
    // Clock and reset
    // ========================================================
    .C_gclk_100M_i      (C_gclk_100M_r),
    .R_gclk_100M_rst_i  (R_gclk_100M_rst_r),

    // ========================================================
    // Control
    // ========================================================
    .start_i            (start_r),
    .done_o             (done_w),
    .result_data_o      (result_data_w)
);

// ============================================================
// Self-check
// ============================================================

initial begin
    fail_count        = 0;
    timeout_count     = 0;
    R_gclk_100M_rst_r = 1'b1;
    start_r           = 1'b0;

    repeat (5) begin
        @(posedge C_gclk_100M_r);
    end
    #1;

    if (done_w !== 1'b0) begin
        $display("CHECK_FAIL: done_o is not reset");
        fail_count = fail_count + 1;
    end

    if (result_data_w !== 8'h00) begin
        $display("CHECK_FAIL: result_data_o is not reset, value=0x%02h", result_data_w);
        fail_count = fail_count + 1;
    end

    R_gclk_100M_rst_r = 1'b0;

    repeat (2) begin
        @(posedge C_gclk_100M_r);
    end
    #1;

    start_r = 1'b1;
    @(posedge C_gclk_100M_r);
    #1;
    start_r = 1'b0;

    while ((done_w !== 1'b1) && (timeout_count < LP_TIMEOUT)) begin
        @(posedge C_gclk_100M_r);
        #1;
        timeout_count = timeout_count + 1;
    end

    if (done_w !== 1'b1) begin
        $display("CHECK_FAIL: done_o timeout after %0d cycles", LP_TIMEOUT);
        fail_count = fail_count + 1;
    end
    else if (result_data_w !== 8'hA5) begin
        $display("CHECK_FAIL: result_data_o mismatch, value=0x%02h", result_data_w);
        fail_count = fail_count + 1;
    end

    @(posedge C_gclk_100M_r);
    #1;

    if (done_w !== 1'b0) begin
        $display("CHECK_FAIL: done_o is not a one-cycle pulse");
        fail_count = fail_count + 1;
    end

    if (fail_count == 0) begin
        $display("RESULT=PASS");
    end
    else begin
        $display("RESULT=FAIL fail_count=%0d", fail_count);
    end

    $finish;
end

endmodule
