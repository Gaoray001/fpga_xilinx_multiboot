# 当前工程交接（下一位 agent 第一屏）

> 只放第一屏；唯一事实源 = 当前任务 `TASK_STATE.md`（纯快照，agent 专用）。
> 本文件每轮全量重写，硬上限 30 行。时间戳：20260720_003126

## 当前任务

20260717_multiboot_ctrl_fsm — S8 Top/UART 逻辑与 testbench 安排梳理完成。

## 关键现状（详见任务 TASK_STATE §2）

- Top 链路：UART RX → `uart_boot_trigger` → `multiboot_ctrl` → `multiboot_icape2_wrapper` → `ICAPE2`。
- 板级事实：50 MHz W19、reset_n N15、UART TX N17/RX P17、Master SPI x4 `M[2:0]=001`。
- Golden offset/WBSTAR=`0x00000000`；Application offset/WBSTAR=`0x00800000`。
- 命令：`BOOT APP\r\n` / `BOOT GOLDEN\r\n`；ACK `0x06` 完整发完后才发 multiboot request。
- controller 输出 8 个配置字：dummy、sync、noop、write WBSTAR、addr、write CMD、IPROG、noop。
- wrapper 使用 X32 ICAPE2，写拍 `CSIB=0/RDWRB=0`，配置字逐 byte bit-reversal。
- S7 原始 run `20260719_232340_xsim-top-uart-multiboot`：`RESULT=PASS`。
- 当前 latest run `20260719_235747_xsim-top-uart-multiboot`：`RESULT=PASS`，WDB 660151 bytes。
- `_runs/latest` 与 `_artifacts/latest` 指向 `common_vivado/20260719_235747_xsim-top-uart-multiboot`。
- S8 仅做逻辑/TB 梳理报告；未改 RTL/TB/Tcl/XDC，未运行 Vivado/综合/实现/bitstream，未上板。

## 下一步唯一动作：人工审查 S8 report；确认理解与边界后另起 S9 Vivado build/property 审计 gate。

## 最新 report 指针

- `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260720_003126_top_uart_logic_and_tb_arrangement_report.md`
