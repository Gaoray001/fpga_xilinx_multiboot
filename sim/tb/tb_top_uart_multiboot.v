`timescale 1ns / 1ps

module tb_top_uart_multiboot;

// ============================================================
// Local parameter
// ============================================================

localparam integer LP_CLK_HALF_NS       = 5;
localparam integer LP_PARAM_CLK_FREQ_HZ = 1_000;
localparam integer LP_PARAM_UART_BAUD   = 100;
localparam integer LP_UART_BIT_CYCLES   = LP_PARAM_CLK_FREQ_HZ / LP_PARAM_UART_BAUD;
localparam integer LP_CMD_TIMEOUT       = LP_PARAM_CLK_FREQ_HZ / 2;
localparam integer LP_NO_EVENT_CYCLES   = 200;
localparam integer LP_ACK_TIMEOUT       = 400;
localparam integer LP_TOP_TIMEOUT       = 2_000;
localparam integer LP_CMD_COUNT         = 8;

localparam [31:0] LP_ADDR_GOLDEN      = 32'h0000_0000;
localparam [31:0] LP_ADDR_APPLICATION = 32'h0080_0000;

// ============================================================
// Testbench signal
// ============================================================

reg C_gclk_50M_r;

reg         trigger_rst_r;
reg         trigger_rx_r;
reg         trigger_req_ready_r;
wire        trigger_tx_w;
wire        trigger_req_valid_w;
wire [31:0] trigger_req_addr_w;

reg top_rst_n_r;
reg top_uart_rx_r;
wire top_uart_tx_w;
wire top_led_w;

reg golden_rst_n_r;
reg golden_uart_rx_r;
wire golden_uart_tx_w;
wire golden_led_w;

integer fail_count;
integer trigger_tx_fall_count;
integer trigger_accept_count;
integer top_tx_fall_count;
integer top_accepted_count;
integer top_monitor_active;
integer top_iprog_count;
integer golden_tx_fall_count;
integer golden_accepted_count;
integer golden_monitor_active;
integer golden_iprog_count;
reg [31:0] trigger_last_addr_r;
reg [31:0] top_expected_addr_r;
reg [31:0] golden_expected_addr_r;

reg trigger_tx_d1_r;
reg top_tx_d1_r;
reg golden_tx_d1_r;

// ============================================================
// Clock
// ============================================================

initial begin
    C_gclk_50M_r = 1'b0;
end

always begin
    #LP_CLK_HALF_NS C_gclk_50M_r = ~C_gclk_50M_r;
end

// ============================================================
// DUTs
// ============================================================

uart_boot_trigger #(
    .PARAM_CLK_FREQ_HZ        (LP_PARAM_CLK_FREQ_HZ),
    .PARAM_BAUD               (LP_PARAM_UART_BAUD),
    .PARAM_CMD_TIMEOUT_CYCLES (LP_CMD_TIMEOUT),
    .PARAM_GOLDEN_ADDR        (LP_ADDR_GOLDEN),
    .PARAM_APPLICATION_ADDR   (LP_ADDR_APPLICATION)
) u_uart_boot_trigger (
    .C_gclk_50M_i             (C_gclk_50M_r),
    .R_gclk_50M_rst_i         (trigger_rst_r),
    .uart_rx_i                (trigger_rx_r),
    .uart_tx_o                (trigger_tx_w),
    .req_valid_o              (trigger_req_valid_w),
    .req_ready_i              (trigger_req_ready_r),
    .req_addr_o               (trigger_req_addr_w)
);

Top #(
    .PARAM_IMAGE_IS_APPLICATION (0),
    .PARAM_CLK_FREQ_HZ          (LP_PARAM_CLK_FREQ_HZ),
    .PARAM_UART_BAUD            (LP_PARAM_UART_BAUD),
    .PARAM_GOLDEN_ADDR          (LP_ADDR_GOLDEN),
    .PARAM_APPLICATION_ADDR     (LP_ADDR_APPLICATION)
) dut (
    .P_G_CLK                    (C_gclk_50M_r),
    .P_G_RST_N                  (top_rst_n_r),
    .P_UART1_TX                 (top_uart_tx_w),
    .P_UART1_RX                 (top_uart_rx_r),
    .P_led_out                  (top_led_w)
);

Top #(
    .PARAM_IMAGE_IS_APPLICATION (0),
    .PARAM_CLK_FREQ_HZ          (LP_PARAM_CLK_FREQ_HZ),
    .PARAM_UART_BAUD            (LP_PARAM_UART_BAUD),
    .PARAM_GOLDEN_ADDR          (LP_ADDR_GOLDEN),
    .PARAM_APPLICATION_ADDR     (LP_ADDR_APPLICATION)
) dut_golden (
    .P_G_CLK                    (C_gclk_50M_r),
    .P_G_RST_N                  (golden_rst_n_r),
    .P_UART1_TX                 (golden_uart_tx_w),
    .P_UART1_RX                 (golden_uart_rx_r),
    .P_led_out                  (golden_led_w)
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
        trigger_rst_r       = 1'b1;
        trigger_rx_r        = 1'b1;
        trigger_req_ready_r = 1'b0;
        top_rst_n_r         = 1'b0;
        top_uart_rx_r       = 1'b1;
        golden_rst_n_r      = 1'b0;
        golden_uart_rx_r    = 1'b1;

        repeat (8) begin
            @(posedge C_gclk_50M_r);
        end
        #1;

        if (trigger_req_valid_w !== 1'b0 || trigger_tx_w !== 1'b1) begin
            report_fail("standalone UART trigger did not reset to idle");
        end
        if (top_uart_tx_w !== 1'b1 || dut.boot_req_valid_w !== 1'b0) begin
            report_fail("Top UART path did not reset to idle");
        end
        if (golden_uart_tx_w !== 1'b1 || dut_golden.boot_req_valid_w !== 1'b0) begin
            report_fail("Golden Top UART path did not reset to idle");
        end

        trigger_rst_r = 1'b0;
        top_rst_n_r   = 1'b1;
        golden_rst_n_r = 1'b1;

        repeat (8) begin
            @(posedge C_gclk_50M_r);
        end
        #1;

        if (dut.boot_req_ready_w !== 1'b1 || dut.ctrl_idle_w !== 1'b1) begin
            report_fail("Top chain did not release reset into idle");
        end
        if (dut_golden.boot_req_ready_w !== 1'b1 || dut_golden.ctrl_idle_w !== 1'b1) begin
            report_fail("Golden Top chain did not release reset into idle");
        end
    end
endtask

task send_trigger_byte;
    input [7:0] data_i;
    integer bit_idx;
    begin
        @(negedge C_gclk_50M_r);
        trigger_rx_r = 1'b0;
        repeat (LP_UART_BIT_CYCLES) begin
            @(posedge C_gclk_50M_r);
        end

        for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
            @(negedge C_gclk_50M_r);
            trigger_rx_r = data_i[bit_idx];
            repeat (LP_UART_BIT_CYCLES) begin
                @(posedge C_gclk_50M_r);
            end
        end

        @(negedge C_gclk_50M_r);
        trigger_rx_r = 1'b1;
        repeat (LP_UART_BIT_CYCLES) begin
            @(posedge C_gclk_50M_r);
        end
    end
endtask

task send_top_byte;
    input [7:0] data_i;
    integer bit_idx;
    begin
        @(negedge C_gclk_50M_r);
        top_uart_rx_r = 1'b0;
        repeat (LP_UART_BIT_CYCLES) begin
            @(posedge C_gclk_50M_r);
        end

        for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
            @(negedge C_gclk_50M_r);
            top_uart_rx_r = data_i[bit_idx];
            repeat (LP_UART_BIT_CYCLES) begin
                @(posedge C_gclk_50M_r);
            end
        end

        @(negedge C_gclk_50M_r);
        top_uart_rx_r = 1'b1;
        repeat (LP_UART_BIT_CYCLES) begin
            @(posedge C_gclk_50M_r);
        end
    end
endtask

task send_golden_byte;
    input [7:0] data_i;
    integer bit_idx;
    begin
        @(negedge C_gclk_50M_r);
        golden_uart_rx_r = 1'b0;
        repeat (LP_UART_BIT_CYCLES) begin
            @(posedge C_gclk_50M_r);
        end

        for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
            @(negedge C_gclk_50M_r);
            golden_uart_rx_r = data_i[bit_idx];
            repeat (LP_UART_BIT_CYCLES) begin
                @(posedge C_gclk_50M_r);
            end
        end

        @(negedge C_gclk_50M_r);
        golden_uart_rx_r = 1'b1;
        repeat (LP_UART_BIT_CYCLES) begin
            @(posedge C_gclk_50M_r);
        end
    end
endtask

task send_trigger_boot_app;
    begin
        send_trigger_byte(8'h42);
        send_trigger_byte(8'h4F);
        send_trigger_byte(8'h4F);
        send_trigger_byte(8'h54);
        send_trigger_byte(8'h20);
        send_trigger_byte(8'h41);
        send_trigger_byte(8'h50);
        send_trigger_byte(8'h50);
        send_trigger_byte(8'h0D);
        send_trigger_byte(8'h0A);
    end
endtask

task send_trigger_boot_golden;
    begin
        send_trigger_byte(8'h42);
        send_trigger_byte(8'h4F);
        send_trigger_byte(8'h4F);
        send_trigger_byte(8'h54);
        send_trigger_byte(8'h20);
        send_trigger_byte(8'h47);
        send_trigger_byte(8'h4F);
        send_trigger_byte(8'h4C);
        send_trigger_byte(8'h44);
        send_trigger_byte(8'h45);
        send_trigger_byte(8'h4E);
        send_trigger_byte(8'h0D);
        send_trigger_byte(8'h0A);
    end
endtask

task send_top_boot_app;
    begin
        send_top_byte(8'h42);
        send_top_byte(8'h4F);
        send_top_byte(8'h4F);
        send_top_byte(8'h54);
        send_top_byte(8'h20);
        send_top_byte(8'h41);
        send_top_byte(8'h50);
        send_top_byte(8'h50);
        send_top_byte(8'h0D);
        send_top_byte(8'h0A);
    end
endtask

task send_top_boot_golden;
    begin
        send_top_byte(8'h42);
        send_top_byte(8'h4F);
        send_top_byte(8'h4F);
        send_top_byte(8'h54);
        send_top_byte(8'h20);
        send_top_byte(8'h47);
        send_top_byte(8'h4F);
        send_top_byte(8'h4C);
        send_top_byte(8'h44);
        send_top_byte(8'h45);
        send_top_byte(8'h4E);
        send_top_byte(8'h0D);
        send_top_byte(8'h0A);
    end
endtask

task send_golden_boot_golden;
    begin
        send_golden_byte(8'h42);
        send_golden_byte(8'h4F);
        send_golden_byte(8'h4F);
        send_golden_byte(8'h54);
        send_golden_byte(8'h20);
        send_golden_byte(8'h47);
        send_golden_byte(8'h4F);
        send_golden_byte(8'h4C);
        send_golden_byte(8'h44);
        send_golden_byte(8'h45);
        send_golden_byte(8'h4E);
        send_golden_byte(8'h0D);
        send_golden_byte(8'h0A);
    end
endtask

task recv_trigger_ack;
    reg [7:0] data;
    integer bit_idx;
    integer timeout;
    begin
        data    = 8'd0;
        timeout = 0;
        while ((trigger_tx_w !== 1'b0) && (timeout < LP_ACK_TIMEOUT)) begin
            @(posedge C_gclk_50M_r);
            #1;
            timeout = timeout + 1;
        end
        if (timeout >= LP_ACK_TIMEOUT) begin
            report_fail("timeout waiting for standalone UART ACK start bit");
        end

        repeat (LP_UART_BIT_CYCLES + (LP_UART_BIT_CYCLES / 2)) begin
            @(posedge C_gclk_50M_r);
            #1;
        end

        for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
            data[bit_idx] = trigger_tx_w;
            repeat (LP_UART_BIT_CYCLES) begin
                @(posedge C_gclk_50M_r);
                #1;
            end
        end

        if (data !== 8'h06) begin
            $display("CHECK_FAIL: standalone ACK got=0x%02h expected=0x06", data);
            fail_count = fail_count + 1;
        end
    end
endtask

task recv_top_ack;
    reg [7:0] data;
    integer bit_idx;
    integer timeout;
    begin
        data    = 8'd0;
        timeout = 0;
        while ((top_uart_tx_w !== 1'b0) && (timeout < LP_ACK_TIMEOUT)) begin
            @(posedge C_gclk_50M_r);
            #1;
            timeout = timeout + 1;
        end
        if (timeout >= LP_ACK_TIMEOUT) begin
            report_fail("timeout waiting for Top UART ACK start bit");
        end

        repeat (LP_UART_BIT_CYCLES + (LP_UART_BIT_CYCLES / 2)) begin
            @(posedge C_gclk_50M_r);
            #1;
        end

        for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
            data[bit_idx] = top_uart_tx_w;
            repeat (LP_UART_BIT_CYCLES) begin
                @(posedge C_gclk_50M_r);
                #1;
            end
        end

        if (data !== 8'h06) begin
            $display("CHECK_FAIL: Top ACK got=0x%02h expected=0x06", data);
            fail_count = fail_count + 1;
        end
    end
endtask

task recv_golden_ack;
    reg [7:0] data;
    integer bit_idx;
    integer timeout;
    begin
        data    = 8'd0;
        timeout = 0;
        while ((golden_uart_tx_w !== 1'b0) && (timeout < LP_ACK_TIMEOUT)) begin
            @(posedge C_gclk_50M_r);
            #1;
            timeout = timeout + 1;
        end
        if (timeout >= LP_ACK_TIMEOUT) begin
            report_fail("timeout waiting for Golden Top UART ACK start bit");
        end

        repeat (LP_UART_BIT_CYCLES + (LP_UART_BIT_CYCLES / 2)) begin
            @(posedge C_gclk_50M_r);
            #1;
        end

        for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
            data[bit_idx] = golden_uart_tx_w;
            repeat (LP_UART_BIT_CYCLES) begin
                @(posedge C_gclk_50M_r);
                #1;
            end
        end

        if (data !== 8'h06) begin
            $display("CHECK_FAIL: Golden Top ACK got=0x%02h expected=0x06", data);
            fail_count = fail_count + 1;
        end
    end
endtask

task wait_no_trigger_request;
    integer timeout;
    integer falls_before;
    begin
        falls_before = trigger_tx_fall_count;
        timeout      = 0;
        while (timeout < LP_NO_EVENT_CYCLES) begin
            @(posedge C_gclk_50M_r);
            #1;
            timeout = timeout + 1;
        end
        if (trigger_req_valid_w !== 1'b0) begin
            report_fail("standalone UART trigger generated an unexpected request");
        end
        if (trigger_tx_fall_count != falls_before) begin
            report_fail("standalone UART trigger generated an unexpected ACK");
        end
    end
endtask

task wait_top_done;
    integer timeout;
    begin
        timeout = 0;
        while ((dut.ctrl_done_w !== 1'b1) && (timeout < LP_TOP_TIMEOUT)) begin
            @(posedge C_gclk_50M_r);
            #1;
            timeout = timeout + 1;
        end
        if (timeout >= LP_TOP_TIMEOUT) begin
            report_fail("timeout waiting for Top controller done");
        end
    end
endtask

task wait_golden_done;
    integer timeout;
    begin
        timeout = 0;
        while ((dut_golden.ctrl_done_w !== 1'b1) && (timeout < LP_TOP_TIMEOUT)) begin
            @(posedge C_gclk_50M_r);
            #1;
            timeout = timeout + 1;
        end
        if (timeout >= LP_TOP_TIMEOUT) begin
            report_fail("timeout waiting for Golden Top controller done");
        end
    end
endtask

task run_top_boot_sequence;
    input [31:0] expected_addr_i;
    input integer is_golden_i;
    integer previous_iprog_count;
    begin
        top_expected_addr_r = expected_addr_i;
        top_accepted_count  = 0;
        previous_iprog_count = top_iprog_count;
        top_monitor_active  = 1;

        if (is_golden_i != 0) begin
            $display("TEST_CASE: Top BOOT GOLDEN to WBSTAR 0x%08h", expected_addr_i);
            send_top_boot_golden;
        end
        else begin
            $display("TEST_CASE: Top BOOT APP to WBSTAR 0x%08h", expected_addr_i);
            send_top_boot_app;
        end

        recv_top_ack;
        wait_top_done;

        if (top_accepted_count != LP_CMD_COUNT) begin
            $display("CHECK_FAIL: Top command count got=%0d expected=%0d",
                     top_accepted_count, LP_CMD_COUNT);
            fail_count = fail_count + 1;
        end
        if (dut.ctrl_target_addr_w !== expected_addr_i) begin
            $display("CHECK_FAIL: Top target address got=0x%08h expected=0x%08h",
                     dut.ctrl_target_addr_w, expected_addr_i);
            fail_count = fail_count + 1;
        end

        repeat (8) begin
            @(posedge C_gclk_50M_r);
            #1;
        end

        if (dut.u_multiboot_icape2_wrapper.u_icape2.SIM_CONFIGE2_INST.wbstar_reg[0]
                !== expected_addr_i) begin
            $display("CHECK_FAIL: Top UNISIM WBSTAR got=0x%08h expected=0x%08h",
                     dut.u_multiboot_icape2_wrapper.u_icape2.SIM_CONFIGE2_INST.wbstar_reg[0],
                     expected_addr_i);
            fail_count = fail_count + 1;
        end
        else begin
            $display("CHECK_PASS: Top UNISIM WBSTAR=0x%08h", expected_addr_i);
        end

        if (top_iprog_count <= previous_iprog_count) begin
            report_fail("Top UNISIM IPROG pulse was not observed");
        end
        else begin
            $display("CHECK_PASS: Top UNISIM IPROG pulse observed");
        end

        top_monitor_active = 0;
    end
endtask

task run_golden_top_boot_sequence;
    integer previous_iprog_count;
    begin
        golden_expected_addr_r = LP_ADDR_GOLDEN;
        golden_accepted_count  = 0;
        previous_iprog_count   = golden_iprog_count;
        golden_monitor_active  = 1;

        $display("TEST_CASE: independent Top BOOT GOLDEN to WBSTAR 0x%08h", LP_ADDR_GOLDEN);
        send_golden_boot_golden;
        recv_golden_ack;
        wait_golden_done;

        if (golden_accepted_count != LP_CMD_COUNT) begin
            $display("CHECK_FAIL: Golden Top command count got=%0d expected=%0d",
                     golden_accepted_count, LP_CMD_COUNT);
            fail_count = fail_count + 1;
        end
        if (dut_golden.ctrl_target_addr_w !== LP_ADDR_GOLDEN) begin
            $display("CHECK_FAIL: Golden Top target address got=0x%08h expected=0x%08h",
                     dut_golden.ctrl_target_addr_w, LP_ADDR_GOLDEN);
            fail_count = fail_count + 1;
        end

        repeat (8) begin
            @(posedge C_gclk_50M_r);
            #1;
        end

        if (dut_golden.u_multiboot_icape2_wrapper.u_icape2.SIM_CONFIGE2_INST.wbstar_reg[0]
                !== LP_ADDR_GOLDEN) begin
            $display("CHECK_FAIL: Golden Top UNISIM WBSTAR got=0x%08h expected=0x%08h",
                     dut_golden.u_multiboot_icape2_wrapper.u_icape2.SIM_CONFIGE2_INST.wbstar_reg[0],
                     LP_ADDR_GOLDEN);
            fail_count = fail_count + 1;
        end
        else begin
            $display("CHECK_PASS: Golden Top UNISIM WBSTAR=0x%08h", LP_ADDR_GOLDEN);
        end

        if (golden_iprog_count <= previous_iprog_count) begin
            report_fail("Golden Top UNISIM IPROG pulse was not observed");
        end
        else begin
            $display("CHECK_PASS: Golden Top UNISIM IPROG pulse observed");
        end

        golden_monitor_active = 0;
    end
endtask

// ============================================================
// Monitors
// ============================================================

always @(posedge C_gclk_50M_r) begin
    trigger_tx_d1_r <= trigger_tx_w;
    top_tx_d1_r     <= top_uart_tx_w;
    golden_tx_d1_r  <= golden_uart_tx_w;

    if (trigger_tx_d1_r && !trigger_tx_w) begin
        trigger_tx_fall_count = trigger_tx_fall_count + 1;
    end
    if (top_tx_d1_r && !top_uart_tx_w) begin
        top_tx_fall_count = top_tx_fall_count + 1;
    end
    if (golden_tx_d1_r && !golden_uart_tx_w) begin
        golden_tx_fall_count = golden_tx_fall_count + 1;
    end

    if (trigger_req_valid_w && trigger_req_ready_r) begin
        trigger_accept_count = trigger_accept_count + 1;
        trigger_last_addr_r  = trigger_req_addr_w;
    end

    if (top_monitor_active != 0) begin
        if (dut.cmd_valid_w && dut.cmd_ready_w) begin
            if (top_accepted_count >= LP_CMD_COUNT) begin
                report_fail("Top transferred more than eight ICAP commands");
            end
            else begin
                if (dut.cmd_data_w !== expected_cmd(top_accepted_count, top_expected_addr_r)) begin
                    $display("CHECK_FAIL: Top cmd[%0d] got=0x%08h expected=0x%08h",
                             top_accepted_count, dut.cmd_data_w,
                             expected_cmd(top_accepted_count, top_expected_addr_r));
                    fail_count = fail_count + 1;
                end
                if (dut.cmd_last_w !== (top_accepted_count == (LP_CMD_COUNT - 1))) begin
                    report_fail("Top cmd_last flag mismatch");
                end
                if (dut.icap_csib_w !== 1'b0 || dut.icap_rdwrb_w !== 1'b0) begin
                    report_fail("Top ICAPE2 controls were not active for a write");
                end
                if (dut.icap_data_i_w !== expected_icap_data(dut.cmd_data_w)) begin
                    $display("CHECK_FAIL: Top ICAP data[%0d] got=0x%08h expected=0x%08h",
                             top_accepted_count, dut.icap_data_i_w,
                             expected_icap_data(dut.cmd_data_w));
                    fail_count = fail_count + 1;
                end
                $display("TOP_ICAP_WRITE: index=%0d logical=0x%08h physical=0x%08h",
                         top_accepted_count, dut.cmd_data_w, dut.icap_data_i_w);
            end
            top_accepted_count = top_accepted_count + 1;
        end
        else if (dut.icap_csib_w !== 1'b1) begin
            report_fail("Top ICAPE2 CSIB was active without a command transfer");
        end
    end

    if (golden_monitor_active != 0) begin
        if (dut_golden.cmd_valid_w && dut_golden.cmd_ready_w) begin
            if (golden_accepted_count >= LP_CMD_COUNT) begin
                report_fail("Golden Top transferred more than eight ICAP commands");
            end
            else begin
                if (dut_golden.cmd_data_w !== expected_cmd(golden_accepted_count, golden_expected_addr_r)) begin
                    $display("CHECK_FAIL: Golden Top cmd[%0d] got=0x%08h expected=0x%08h",
                             golden_accepted_count, dut_golden.cmd_data_w,
                             expected_cmd(golden_accepted_count, golden_expected_addr_r));
                    fail_count = fail_count + 1;
                end
                if (dut_golden.cmd_last_w !== (golden_accepted_count == (LP_CMD_COUNT - 1))) begin
                    report_fail("Golden Top cmd_last flag mismatch");
                end
                if (dut_golden.icap_csib_w !== 1'b0 || dut_golden.icap_rdwrb_w !== 1'b0) begin
                    report_fail("Golden Top ICAPE2 controls were not active for a write");
                end
                if (dut_golden.icap_data_i_w !== expected_icap_data(dut_golden.cmd_data_w)) begin
                    $display("CHECK_FAIL: Golden Top ICAP data[%0d] got=0x%08h expected=0x%08h",
                             golden_accepted_count, dut_golden.icap_data_i_w,
                             expected_icap_data(dut_golden.cmd_data_w));
                    fail_count = fail_count + 1;
                end
                $display("GOLDEN_TOP_ICAP_WRITE: index=%0d logical=0x%08h physical=0x%08h",
                         golden_accepted_count, dut_golden.cmd_data_w, dut_golden.icap_data_i_w);
            end
            golden_accepted_count = golden_accepted_count + 1;
        end
        else if (dut_golden.icap_csib_w !== 1'b1) begin
            report_fail("Golden Top ICAPE2 CSIB was active without a command transfer");
        end
    end
end

always @(negedge dut.u_multiboot_icape2_wrapper.u_icape2.SIM_CONFIGE2_INST.iprog_b[0]) begin
    top_iprog_count = top_iprog_count + 1;
end

always @(negedge dut_golden.u_multiboot_icape2_wrapper.u_icape2.SIM_CONFIGE2_INST.iprog_b[0]) begin
    golden_iprog_count = golden_iprog_count + 1;
end

// ============================================================
// Test sequence
// ============================================================

initial begin
    fail_count            = 0;
    trigger_tx_fall_count = 0;
    trigger_accept_count  = 0;
    top_tx_fall_count     = 0;
    top_accepted_count    = 0;
    top_monitor_active    = 0;
    top_iprog_count       = 0;
    golden_tx_fall_count  = 0;
    golden_accepted_count = 0;
    golden_monitor_active = 0;
    golden_iprog_count    = 0;
    trigger_last_addr_r   = 32'd0;
    top_expected_addr_r   = 32'd0;
    golden_expected_addr_r = 32'd0;
    trigger_tx_d1_r       = 1'b1;
    top_tx_d1_r           = 1'b1;
    golden_tx_d1_r        = 1'b1;

    $display("TEST_CASE: reset and UNISIM initialization");
    apply_reset;

    repeat (220) begin
        @(posedge C_gclk_50M_r);
    end
    #1;
    if (dut.u_multiboot_icape2_wrapper.u_icape2.icap_idone !== 1'b1) begin
        report_fail("Top UNISIM ICAPE2 model did not finish initialization");
    end
    else begin
        $display("CHECK_PASS: Top UNISIM ICAPE2 initialization observed");
    end
    if (dut_golden.u_multiboot_icape2_wrapper.u_icape2.icap_idone !== 1'b1) begin
        report_fail("Golden Top UNISIM ICAPE2 model did not finish initialization");
    end
    else begin
        $display("CHECK_PASS: Golden Top UNISIM ICAPE2 initialization observed");
    end

    $display("TEST_CASE: standalone UART rejects bad command");
    send_trigger_byte(8'h42);
    send_trigger_byte(8'h4F);
    send_trigger_byte(8'h4F);
    send_trigger_byte(8'h54);
    send_trigger_byte(8'h20);
    send_trigger_byte(8'h42);
    send_trigger_byte(8'h41);
    send_trigger_byte(8'h44);
    send_trigger_byte(8'h0D);
    send_trigger_byte(8'h0A);
    wait_no_trigger_request;

    $display("TEST_CASE: standalone UART partial command timeout");
    send_trigger_byte(8'h42);
    send_trigger_byte(8'h4F);
    send_trigger_byte(8'h4F);
    send_trigger_byte(8'h54);
    send_trigger_byte(8'h20);
    send_trigger_byte(8'h41);
    repeat (LP_CMD_TIMEOUT + 40) begin
        @(posedge C_gclk_50M_r);
    end
    send_trigger_byte(8'h50);
    send_trigger_byte(8'h50);
    send_trigger_byte(8'h0D);
    send_trigger_byte(8'h0A);
    wait_no_trigger_request;

    $display("TEST_CASE: standalone UART ACK then valid-ready backpressure hold");
    trigger_req_ready_r = 1'b0;
    send_trigger_boot_app;
    recv_trigger_ack;
    repeat (8) begin
        @(posedge C_gclk_50M_r);
        #1;
    end
    if (trigger_req_valid_w !== 1'b1 || trigger_req_addr_w !== LP_ADDR_APPLICATION) begin
        report_fail("standalone UART did not hold APP request under backpressure");
    end

    send_trigger_boot_golden;
    repeat (16) begin
        @(posedge C_gclk_50M_r);
        #1;
    end
    if (trigger_req_valid_w !== 1'b1 || trigger_req_addr_w !== LP_ADDR_APPLICATION) begin
        report_fail("standalone UART request was overwritten while backpressured");
    end

    trigger_req_ready_r = 1'b1;
    repeat (4) begin
        @(posedge C_gclk_50M_r);
        #1;
    end
    if (trigger_accept_count != 1 || trigger_last_addr_r !== LP_ADDR_APPLICATION) begin
        report_fail("standalone UART APP request did not handshake correctly");
    end

    $display("TEST_CASE: standalone UART BOOT GOLDEN request");
    send_trigger_boot_golden;
    recv_trigger_ack;
    repeat (8) begin
        @(posedge C_gclk_50M_r);
        #1;
    end
    if (trigger_accept_count != 2 || trigger_last_addr_r !== LP_ADDR_GOLDEN) begin
        report_fail("standalone UART GOLDEN request did not handshake correctly");
    end

    run_top_boot_sequence(LP_ADDR_APPLICATION, 0);
    run_golden_top_boot_sequence;

    if (fail_count == 0) begin
        $display("RESULT=PASS");
    end
    else begin
        $display("RESULT=FAIL fail_count=%0d", fail_count);
    end

    $finish;
end

endmodule
