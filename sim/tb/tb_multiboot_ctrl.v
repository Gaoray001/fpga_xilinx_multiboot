`timescale 1ns / 1ps

module tb_multiboot_ctrl;

// ============================================================
// Local parameter
// ============================================================

localparam integer LP_CLK_HALF_NS = 5;
localparam integer LP_TIMEOUT     = 128;
localparam integer LP_CMD_COUNT   = 8;

localparam [31:0] LP_ADDR_A = 32'h0010_0000;
localparam [31:0] LP_ADDR_B = 32'h0020_0000;
localparam [31:0] LP_ADDR_C = 32'h0030_0000;
localparam [31:0] LP_ADDR_D = 32'h0040_0000;

// ============================================================
// Testbench signal
// ============================================================

reg         C_gclk_100M_r;
reg         R_gclk_100M_rst_r;
reg         req_valid_r;
reg [31:0]  req_addr_r;
reg         cmd_ready_r;

wire        req_ready_w;
wire        cmd_valid_w;
wire [31:0] cmd_data_w;
wire        cmd_last_w;
wire        idle_w;
wire        busy_w;
wire        done_w;
wire        err_w;
wire [2:0]  state_w;
wire [3:0]  cmd_index_w;
wire [31:0] target_addr_w;

integer fail_count;

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

multiboot_ctrl u_multiboot_ctrl (
    // ========================================================
    // Clock and reset
    // ========================================================
    .C_gclk_100M_i      (C_gclk_100M_r),
    .R_gclk_100M_rst_i  (R_gclk_100M_rst_r),

    // ========================================================
    // Multiboot request
    // ========================================================
    .req_valid_i        (req_valid_r),
    .req_ready_o        (req_ready_w),
    .req_addr_i         (req_addr_r),

    // ========================================================
    // Abstract ICAP command stream
    // ========================================================
    .cmd_valid_o        (cmd_valid_w),
    .cmd_ready_i        (cmd_ready_r),
    .cmd_data_o         (cmd_data_w),
    .cmd_last_o         (cmd_last_w),

    // ========================================================
    // Status
    // ========================================================
    .idle_o             (idle_w),
    .busy_o             (busy_w),
    .done_o             (done_w),
    .err_o              (err_w),
    .state_o            (state_w),
    .cmd_index_o        (cmd_index_w),
    .target_addr_o      (target_addr_w)
);

// ============================================================
// Expected sequence
// ============================================================

function [31:0] expected_cmd;
    input integer index;
    input [31:0]  addr;
    begin
        case (index)
            0: expected_cmd = 32'hFFFFFFFF;
            1: expected_cmd = 32'hAA995566;
            2: expected_cmd = 32'h20000000;
            3: expected_cmd = 32'h30020001;
            4: expected_cmd = addr;
            5: expected_cmd = 32'h30008001;
            6: expected_cmd = 32'h0000000F;
            7: expected_cmd = 32'h20000000;
            default: expected_cmd = 32'hDEAD_BEEF;
        endcase
    end
endfunction

task report_fail;
    input [1023:0] message;
    begin
        $display("CHECK_FAIL: %0s", message);
        fail_count = fail_count + 1;
    end
endtask

task apply_reset;
    begin
        R_gclk_100M_rst_r = 1'b1;
        req_valid_r       = 1'b0;
        req_addr_r        = 32'd0;
        cmd_ready_r       = 1'b0;

        repeat (3) begin
            @(posedge C_gclk_100M_r);
        end
        #1;

        if (idle_w !== 1'b1) begin
            report_fail("DUT is not idle during reset");
        end
        if (cmd_valid_w !== 1'b0) begin
            report_fail("cmd_valid_o is not cleared during reset");
        end
        if (target_addr_w !== 32'd0) begin
            report_fail("target_addr_o is not cleared during reset");
        end

        R_gclk_100M_rst_r = 1'b0;

        repeat (2) begin
            @(posedge C_gclk_100M_r);
        end
        #1;

        if (idle_w !== 1'b1 || req_ready_w !== 1'b1 || err_w !== 1'b0) begin
            report_fail("DUT did not return to idle after reset release");
        end
    end
endtask

task issue_request;
    input [31:0] addr;
    begin
        req_addr_r  = addr;
        req_valid_r = 1'b1;

        @(posedge C_gclk_100M_r);
        if (req_ready_w !== 1'b1) begin
            report_fail("request was not accepted while idle");
        end
        #1;

        req_valid_r = 1'b0;

        if (busy_w !== 1'b1 || idle_w !== 1'b0) begin
            report_fail("DUT did not enter busy state after request");
        end
        if (target_addr_w !== addr) begin
            report_fail("target address was not latched on request");
        end
    end
endtask

task check_sequence_word;
    input integer index;
    input [31:0]  addr;
    reg [31:0] expected_data;
    begin
        expected_data = expected_cmd(index, addr);
        if (cmd_data_w !== expected_data) begin
            $display("CHECK_FAIL: command[%0d] data mismatch, got=0x%08h expected=0x%08h",
                     index, cmd_data_w, expected_data);
            fail_count = fail_count + 1;
        end
        if (cmd_index_w !== index[3:0]) begin
            $display("CHECK_FAIL: command index mismatch, got=%0d expected=%0d",
                     cmd_index_w, index);
            fail_count = fail_count + 1;
        end
        if (cmd_last_w !== (index == (LP_CMD_COUNT - 1))) begin
            $display("CHECK_FAIL: cmd_last mismatch at index %0d", index);
            fail_count = fail_count + 1;
        end
    end
endtask

task run_expected_sequence;
    input [31:0] addr;
    input integer ready_mode;
    input integer inject_busy_req;
    input [31:0] busy_addr;
    integer count;
    integer timeout;
    integer busy_req_sent;
    integer busy_req_cleared;
    integer hold_valid;
    reg [31:0] hold_data;
    reg hold_last;
    begin
        count            = 0;
        timeout          = 0;
        busy_req_sent    = 0;
        busy_req_cleared = 0;
        hold_valid       = 0;
        hold_data        = 32'd0;
        hold_last        = 1'b0;
        cmd_ready_r      = 1'b1;

        while ((done_w !== 1'b1) && (timeout < LP_TIMEOUT)) begin
            @(posedge C_gclk_100M_r);

            if (req_valid_r && req_ready_w) begin
                report_fail("busy request was unexpectedly accepted");
            end

            if (cmd_valid_w && !cmd_ready_r) begin
                if (hold_valid) begin
                    if (cmd_data_w !== hold_data || cmd_last_w !== hold_last) begin
                        report_fail("command changed while cmd_ready_i was low");
                    end
                end
                else begin
                    hold_valid = 1;
                    hold_data  = cmd_data_w;
                    hold_last  = cmd_last_w;
                end
            end

            if (cmd_valid_w && cmd_ready_r) begin
                check_sequence_word(count, addr);
                count      = count + 1;
                hold_valid = 0;
            end

            #1;

            if (inject_busy_req && !busy_req_sent && count >= 2 && busy_w) begin
                req_addr_r     = busy_addr;
                req_valid_r    = 1'b1;
                busy_req_sent  = 1;
            end
            else if (busy_req_sent && !busy_req_cleared) begin
                req_valid_r        = 1'b0;
                busy_req_cleared   = 1;
            end

            if (ready_mode == 0) begin
                cmd_ready_r = 1'b1;
            end
            else begin
                cmd_ready_r = (timeout[1:0] != 2'd1);
            end

            timeout = timeout + 1;
        end

        req_valid_r = 1'b0;
        cmd_ready_r = 1'b0;

        if (timeout >= LP_TIMEOUT) begin
            report_fail("sequence timeout");
        end
        if (count != LP_CMD_COUNT) begin
            $display("CHECK_FAIL: command count mismatch, got=%0d expected=%0d",
                     count, LP_CMD_COUNT);
            fail_count = fail_count + 1;
        end
        if (done_w !== 1'b1) begin
            report_fail("done_o was not asserted at sequence end");
        end
        if (target_addr_w !== addr) begin
            report_fail("target address changed during sequence");
        end

        @(posedge C_gclk_100M_r);
        #1;

        if (done_w !== 1'b0 || idle_w !== 1'b1 || req_ready_w !== 1'b1) begin
            report_fail("DUT did not return to idle after done pulse");
        end
    end
endtask

task run_reset_mid_sequence_test;
    integer fires;
    integer timeout;
    begin
        apply_reset;
        issue_request(LP_ADDR_C);
        cmd_ready_r = 1'b1;
        fires       = 0;
        timeout     = 0;

        while ((fires < 3) && (timeout < LP_TIMEOUT)) begin
            @(posedge C_gclk_100M_r);
            if (cmd_valid_w && cmd_ready_r) begin
                fires = fires + 1;
            end
            #1;
            timeout = timeout + 1;
        end

        if (fires < 3) begin
            report_fail("reset test did not observe initial command fires");
        end

        R_gclk_100M_rst_r = 1'b1;
        req_valid_r       = 1'b0;
        cmd_ready_r       = 1'b1;

        repeat (2) begin
            @(posedge C_gclk_100M_r);
        end
        #1;

        if (idle_w !== 1'b1 || busy_w !== 1'b0 || cmd_valid_w !== 1'b0) begin
            report_fail("reset did not abort in-flight sequence");
        end
        if (target_addr_w !== 32'd0) begin
            report_fail("reset did not clear latched target address");
        end

        R_gclk_100M_rst_r = 1'b0;

        repeat (2) begin
            @(posedge C_gclk_100M_r);
        end
        #1;

        issue_request(LP_ADDR_D);
        run_expected_sequence(LP_ADDR_D, 1, 0, 32'd0);
    end
endtask

// ============================================================
// Test sequence
// ============================================================

initial begin
    fail_count        = 0;
    R_gclk_100M_rst_r = 1'b1;
    req_valid_r       = 1'b0;
    req_addr_r        = 32'd0;
    cmd_ready_r       = 1'b0;

    $display("TEST_START: multiboot_ctrl functional simulation");

    apply_reset;
    $display("TEST_CASE: continuous ready");
    issue_request(LP_ADDR_A);
    run_expected_sequence(LP_ADDR_A, 0, 0, 32'd0);

    apply_reset;
    $display("TEST_CASE: intermittent ready");
    issue_request(LP_ADDR_B);
    run_expected_sequence(LP_ADDR_B, 1, 0, 32'd0);

    apply_reset;
    $display("TEST_CASE: busy request ignored");
    issue_request(LP_ADDR_A);
    run_expected_sequence(LP_ADDR_A, 1, 1, LP_ADDR_B);

    $display("TEST_CASE: reset mid sequence");
    run_reset_mid_sequence_test;

    if (fail_count == 0) begin
        $display("RESULT=PASS");
    end
    else begin
        $display("RESULT=FAIL fail_count=%0d", fail_count);
    end

    $finish;
end

endmodule
