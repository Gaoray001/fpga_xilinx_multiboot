`timescale 1ns / 1ps

module tb_multiboot_ctrl;

// ============================================================
// Local parameter
// ============================================================

localparam integer LP_CLK_HALF_NS = 5;
localparam integer LP_TIMEOUT     = 256;
localparam integer LP_CMD_COUNT   = 8;

localparam [31:0] LP_ADDR_ABORT = 32'h0010_0000;
localparam [31:0] LP_ADDR_BOOT  = 32'h0020_0000;
localparam [31:0] LP_ADDR_BUSY  = 32'h0030_0000;

// ============================================================
// Testbench signal
// ============================================================

reg         C_gclk_100M_r;
reg         R_gclk_100M_rst_r;
reg         req_valid_r;
reg [31:0]  req_addr_r;
reg         icap_enable_r;

wire        req_ready_w;
wire        cmd_valid_w;
wire        cmd_ready_w;
wire [31:0] cmd_data_w;
wire        cmd_last_w;
wire        idle_w;
wire        busy_w;
wire        done_w;
wire        err_w;
wire [2:0]  state_w;
wire [3:0]  cmd_index_w;
wire [31:0] target_addr_w;

wire        icap_csib_w;
wire        icap_rdwrb_w;
wire [31:0] icap_data_i_w;
wire [31:0] icap_data_o_w;

integer fail_count;
integer accepted_count;
integer monitor_active;
integer iprog_seen;
reg [31:0] expected_addr_r;

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
// DUT chain
// ============================================================

multiboot_ctrl u_multiboot_ctrl (
    .C_gclk_100M_i      (C_gclk_100M_r),
    .R_gclk_100M_rst_i  (R_gclk_100M_rst_r),
    .req_valid_i        (req_valid_r),
    .req_ready_o        (req_ready_w),
    .req_addr_i         (req_addr_r),
    .cmd_valid_o        (cmd_valid_w),
    .cmd_ready_i        (cmd_ready_w),
    .cmd_data_o         (cmd_data_w),
    .cmd_last_o         (cmd_last_w),
    .idle_o             (idle_w),
    .busy_o             (busy_w),
    .done_o             (done_w),
    .err_o              (err_w),
    .state_o            (state_w),
    .cmd_index_o        (cmd_index_w),
    .target_addr_o      (target_addr_w)
);

multiboot_icape2_wrapper u_multiboot_icape2_wrapper (
    .C_gclk_100M_i      (C_gclk_100M_r),
    .R_gclk_100M_rst_i  (R_gclk_100M_rst_r),
    .cmd_valid_i        (cmd_valid_w),
    .cmd_ready_o        (cmd_ready_w),
    .cmd_data_i         (cmd_data_w),
    .icap_enable_i      (icap_enable_r),
    .icap_csib_o        (icap_csib_w),
    .icap_rdwrb_o       (icap_rdwrb_w),
    .icap_data_i_o      (icap_data_i_w),
    .icap_data_o_o      (icap_data_o_w)
);

// ============================================================
// Expected values
// ============================================================

function [31:0] expected_cmd;
    input integer index;
    input [31:0]  addr;
    begin
        case (index)
            0: expected_cmd = 32'hFFFF_FFFF;
            1: expected_cmd = 32'hAA99_5566;
            2: expected_cmd = 32'h2000_0000;
            3: expected_cmd = 32'h3002_0001;
            4: expected_cmd = addr;
            5: expected_cmd = 32'h3000_8001;
            6: expected_cmd = 32'h0000_000F;
            7: expected_cmd = 32'h2000_0000;
            default: expected_cmd = 32'hDEAD_BEEF;
        endcase
    end
endfunction

function [7:0] bit_reverse_byte;
    input [7:0] data_i;
    begin
        bit_reverse_byte = {
            data_i[0], data_i[1], data_i[2], data_i[3],
            data_i[4], data_i[5], data_i[6], data_i[7]
        };
    end
endfunction

function [31:0] expected_icap_data;
    input [31:0] logical_data_i;
    begin
        expected_icap_data = {
            bit_reverse_byte(logical_data_i[31:24]),
            bit_reverse_byte(logical_data_i[23:16]),
            bit_reverse_byte(logical_data_i[15:8]),
            bit_reverse_byte(logical_data_i[7:0])
        };
    end
endfunction

// ============================================================
// Self-check helpers
// ============================================================

task report_fail;
    input [1023:0] message;
    begin
        $display("CHECK_FAIL: %0s", message);
        fail_count = fail_count + 1;
    end
endtask

task apply_reset;
    begin
        @(negedge C_gclk_100M_r);
        R_gclk_100M_rst_r = 1'b1;
        req_valid_r       = 1'b0;
        req_addr_r        = 32'd0;
        icap_enable_r     = 1'b1;

        repeat (3) begin
            @(posedge C_gclk_100M_r);
        end
        #1;

        if (idle_w !== 1'b1 || busy_w !== 1'b0) begin
            report_fail("controller is not idle during reset");
        end
        if (cmd_valid_w !== 1'b0 || cmd_ready_w !== 1'b0) begin
            report_fail("command interface is not inactive during reset");
        end
        if (icap_csib_w !== 1'b1 || icap_rdwrb_w !== 1'b0) begin
            report_fail("ICAPE2 controls are not inactive write mode during reset");
        end
        if (target_addr_w !== 32'd0) begin
            report_fail("target address is not cleared during reset");
        end

        @(negedge C_gclk_100M_r);
        R_gclk_100M_rst_r = 1'b0;
        @(posedge C_gclk_100M_r);
        #1;

        if (idle_w !== 1'b1 || req_ready_w !== 1'b1 || err_w !== 1'b0) begin
            report_fail("controller did not return to idle after reset release");
        end
    end
endtask

task issue_request;
    input [31:0] addr;
    begin
        @(negedge C_gclk_100M_r);
        req_addr_r  = addr;
        req_valid_r = 1'b1;

        @(posedge C_gclk_100M_r);
        if (req_ready_w !== 1'b1) begin
            report_fail("request was not accepted while idle");
        end
        #1;
        req_valid_r = 1'b0;

        if (busy_w !== 1'b1 || target_addr_w !== addr) begin
            report_fail("request did not enter busy with the latched address");
        end
    end
endtask

task wait_fire_count;
    input integer target_count;
    integer timeout;
    begin
        timeout = 0;
        while ((accepted_count < target_count) && (timeout < LP_TIMEOUT)) begin
            @(negedge C_gclk_100M_r);
            timeout = timeout + 1;
        end
        if (timeout >= LP_TIMEOUT) begin
            report_fail("timeout waiting for command transfer count");
        end
    end
endtask

task pause_current_word;
    integer count_before;
    reg [31:0] held_data;
    reg        held_last;
    begin
        @(negedge C_gclk_100M_r);
        if (cmd_valid_w !== 1'b1) begin
            report_fail("no command valid before backpressure test");
        end

        count_before  = accepted_count;
        held_data     = cmd_data_w;
        held_last     = cmd_last_w;
        icap_enable_r = 1'b0;

        repeat (3) begin
            @(posedge C_gclk_100M_r);
            #1;
            if (cmd_valid_w !== 1'b1 || cmd_ready_w !== 1'b0) begin
                report_fail("command valid/ready changed incorrectly under backpressure");
            end
            if (cmd_data_w !== held_data || cmd_last_w !== held_last) begin
                report_fail("command payload changed under backpressure");
            end
            if (icap_csib_w !== 1'b1) begin
                report_fail("ICAPE2 was selected while wrapper was backpressured");
            end
        end

        if (accepted_count != count_before) begin
            report_fail("a command transferred while ICAP enable was low");
        end

        @(negedge C_gclk_100M_r);
        icap_enable_r = 1'b1;
    end
endtask

task inject_busy_request;
    begin
        @(negedge C_gclk_100M_r);
        req_addr_r  = LP_ADDR_BUSY;
        req_valid_r = 1'b1;

        @(posedge C_gclk_100M_r);
        if (req_ready_w !== 1'b0) begin
            report_fail("busy request unexpectedly observed ready");
        end
        #1;
        req_valid_r = 1'b0;

        if (target_addr_w !== LP_ADDR_BOOT) begin
            report_fail("busy request overwrote the active target address");
        end
    end
endtask

task wait_done;
    integer timeout;
    begin
        timeout = 0;
        while ((done_w !== 1'b1) && (timeout < LP_TIMEOUT)) begin
            @(negedge C_gclk_100M_r);
            timeout = timeout + 1;
        end
        if (timeout >= LP_TIMEOUT) begin
            report_fail("timeout waiting for done pulse");
        end
    end
endtask

// ============================================================
// Command and ICAPE2 pin monitor
// ============================================================

always @(posedge C_gclk_100M_r) begin
    if (monitor_active != 0) begin
        if (cmd_valid_w && cmd_ready_w) begin
            if (accepted_count >= LP_CMD_COUNT) begin
                report_fail("more than eight commands were transferred");
            end
            else begin
                if (cmd_data_w !== expected_cmd(accepted_count, expected_addr_r)) begin
                    $display("CHECK_FAIL: command[%0d] got=0x%08h expected=0x%08h",
                             accepted_count, cmd_data_w,
                             expected_cmd(accepted_count, expected_addr_r));
                    fail_count = fail_count + 1;
                end
                if (cmd_index_w !== accepted_count[3:0]) begin
                    report_fail("command index did not match transfer count");
                end
                if (cmd_last_w !== (accepted_count == (LP_CMD_COUNT - 1))) begin
                    report_fail("command last flag was incorrect");
                end
                if (icap_csib_w !== 1'b0 || icap_rdwrb_w !== 1'b0) begin
                    report_fail("ICAPE2 controls were not active for a write transfer");
                end
                if (icap_data_i_w !== expected_icap_data(cmd_data_w)) begin
                    $display("CHECK_FAIL: ICAP data[%0d] got=0x%08h expected=0x%08h",
                             accepted_count, icap_data_i_w,
                             expected_icap_data(cmd_data_w));
                    fail_count = fail_count + 1;
                end
                $display("ICAP_WRITE: index=%0d logical=0x%08h physical=0x%08h",
                         accepted_count, cmd_data_w, icap_data_i_w);
            end
            accepted_count = accepted_count + 1;
        end
        else if (icap_csib_w !== 1'b1) begin
            report_fail("ICAPE2 CSIB was active without a command transfer");
        end
    end
end

always @(negedge u_multiboot_icape2_wrapper.u_icape2.SIM_CONFIGE2_INST.iprog_b[0]) begin
    iprog_seen = 1;
end

// ============================================================
// Test sequence
// ============================================================

initial begin
    fail_count       = 0;
    accepted_count   = 0;
    monitor_active   = 0;
    iprog_seen       = 0;
    expected_addr_r  = 32'd0;
    R_gclk_100M_rst_r = 1'b1;
    req_valid_r       = 1'b0;
    req_addr_r        = 32'd0;
    icap_enable_r     = 1'b0;

    $display("TEST_CASE: wait for UNISIM ICAPE2 initialization");
    apply_reset;
    icap_enable_r = 1'b0;
    repeat (200) begin
        @(posedge C_gclk_100M_r);
    end
    #1;
    if (u_multiboot_icape2_wrapper.u_icape2.icap_idone !== 1'b1) begin
        report_fail("UNISIM ICAPE2 model did not finish initialization");
    end
    else begin
        $display("CHECK_PASS: UNISIM ICAPE2 initialization observed");
    end

    $display("TEST_CASE: reset aborts an in-flight controller-to-ICAPE2 stream");
    apply_reset;
    accepted_count  = 0;
    expected_addr_r = LP_ADDR_ABORT;
    monitor_active  = 1;
    issue_request(LP_ADDR_ABORT);
    wait_fire_count(1);

    R_gclk_100M_rst_r = 1'b1;
    repeat (2) begin
        @(posedge C_gclk_100M_r);
    end
    #1;
    if (accepted_count != 1) begin
        report_fail("reset did not stop the partial command stream");
    end
    if (idle_w !== 1'b1 || cmd_valid_w !== 1'b0 || icap_csib_w !== 1'b1) begin
        report_fail("reset did not return the chain to its inactive state");
    end
    if (target_addr_w !== 32'd0) begin
        report_fail("reset did not clear the latched target address");
    end
    monitor_active = 0;

    $display("TEST_CASE: full WBSTAR/IPROG sequence with backpressure and busy request");
    apply_reset;
    accepted_count  = 0;
    expected_addr_r = LP_ADDR_BOOT;
    iprog_seen      = 0;
    monitor_active  = 1;
    issue_request(LP_ADDR_BOOT);
    pause_current_word;
    wait_fire_count(3);
    inject_busy_request;
    wait_done;

    if (accepted_count != LP_CMD_COUNT) begin
        $display("CHECK_FAIL: command count got=%0d expected=%0d",
                 accepted_count, LP_CMD_COUNT);
        fail_count = fail_count + 1;
    end
    if (target_addr_w !== LP_ADDR_BOOT) begin
        report_fail("target address changed during the completed sequence");
    end

    repeat (4) begin
        @(posedge C_gclk_100M_r);
    end
    #1;
    if (u_multiboot_icape2_wrapper.u_icape2.SIM_CONFIGE2_INST.wbstar_reg[0]
            !== LP_ADDR_BOOT) begin
        $display("CHECK_FAIL: UNISIM WBSTAR got=0x%08h expected=0x%08h",
                 u_multiboot_icape2_wrapper.u_icape2.SIM_CONFIGE2_INST.wbstar_reg[0],
                 LP_ADDR_BOOT);
        fail_count = fail_count + 1;
    end
    else begin
        $display("CHECK_PASS: UNISIM WBSTAR=0x%08h", LP_ADDR_BOOT);
    end
    if (iprog_seen == 0) begin
        report_fail("UNISIM model did not decode the IPROG command");
    end
    else begin
        $display("CHECK_PASS: UNISIM IPROG pulse observed");
    end

    monitor_active = 0;

    if (fail_count == 0) begin
        $display("RESULT=PASS");
    end
    else begin
        $display("RESULT=FAIL fail_count=%0d", fail_count);
    end

    $finish;
end

endmodule
