# 当前工程交接（下一位 agent 第一屏）

> 只放第一屏；唯一事实源 = 当前任务 `TASK_STATE.md`（纯快照，agent 专用）。
> 本文件每轮全量重写，硬上限 30 行。时间戳：20260719_232416

## 当前任务

20260717_multiboot_ctrl_fsm — S7 Top + UART Linux Vivado XSim gate 完成。

## 关键现状（详见任务 TASK_STATE §2）

- 已实现 `multiboot_ctrl → multiboot_icape2_wrapper → ICAPE2`，X32、写拍 `CSIB=0/RDWRB=0`、逐 byte bit-reversal。
- 板级事实：50 MHz W19、reset_n N15、UART TX N17/RX P17、Master SPI x4 `M[2:0]=001`。
- Golden offset/WBSTAR=`0x00000000`；Application offset/WBSTAR=`0x00800000`。
- `Top.v` 已接入 UART trigger → controller → wrapper；Golden 1 Hz，参数化 Application 4 Hz。
- 命令：`BOOT APP\r\n` / `BOOT GOLDEN\r\n`；ACK `0x06` 后发 request，含 CDC/500 ms timeout。
- XDC 已补 20 ns clock/UART pins；CONFIGRATE=12、fallback/timer、no compression、无 NEXT_CONFIG。
- S7 新增 Top/UART XSim 入口：`tb_top_uart_multiboot.v`、`xsim_top_uart_multiboot.tcl`、`xsim-top-uart-multiboot`。
- 最终 run `20260719_232340_xsim-top-uart-multiboot`：`RESULT=PASS`，`xvlog/xelab/xsim` 成功。
- xelab 含 `Top`、`uart_boot_trigger`、`multiboot_ctrl`、`multiboot_icape2_wrapper`、`unisims_ver.ICAPE2/SIM_CONFIGE2`。
- 自检覆盖非法命令、partial timeout、ACK、valid-ready backpressure hold、APP/GOLDEN WBSTAR、IPROG。
- WDB：`_artifacts/common_vivado/20260719_232340_xsim-top-uart-multiboot/top_uart_multiboot.wdb`；`_runs/latest`/`_artifacts/latest` 指向该成功 run。
- 本轮运行 Vivado XSim；未运行综合/实现/bitstream/MCS，未上板。

## 下一步唯一动作：人工审查 S7 report 与 TB/Tcl/Shell diff；确认后另起 S8 Vivado build/property 审计 gate。

## 最新 report 指针

- `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260719_232416_top_uart_xsim_report.md`
