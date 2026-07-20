# 当前工程交接（下一位 agent 第一屏）

> 只放第一屏；唯一事实源 = 当前任务 `TASK_STATE.md`（纯快照，agent 专用）。
> 本文件每轮全量重写，硬上限 30 行。时间戳：20260719_205547

## 当前任务

20260717_multiboot_ctrl_fsm — S6 Top + UART 集成/静态自检完成。

## 关键现状（详见任务 TASK_STATE §2）

- 已实现 `multiboot_ctrl → multiboot_icape2_wrapper → ICAPE2`，抽象 controller 未绑定器件原语。
- wrapper 使用 X32 ICAPE2，实际写拍 `CSIB=0` / `RDWRB=0`，配置字逐 byte bit-reversal。
- 自检 TB 覆盖顺序/数量/物理数据、reset、busy 新请求、backpressure、UNISIM WBSTAR/IPROG 解码。
- 最终 run `20260719_024313_xsim-multiboot-ctrl`：`RESULT=PASS`，xelab 含 `unisims_ver.ICAPE2/SIM_CONFIGE2`。
- 板级事实：50 MHz W19、reset_n N15、UART TX N17/RX P17、Master SPI x4 `M[2:0]=001`。
- Golden offset/WBSTAR=`0x00000000`；Application offset/WBSTAR=`0x00800000`。
- `Top.v` 已接入 UART trigger → controller → wrapper；Golden 1 Hz，参数化 Application 4 Hz。
- 命令：`BOOT APP\r\n` / `BOOT GOLDEN\r\n`；ACK `0x06` 后发 request，含 CDC/500 ms timeout。
- XDC 已补 20 ns clock/UART pins；CONFIGRATE=12、fallback/timer、no compression、无 NEXT_CONFIG。
- 非 Vivado 结构化静态检查 PASS；不等于 HDL 编译/XSim/综合/上板 PASS。
- 本轮未运行 Vivado、未生成 bitstream/MCS、未上板。

## 下一步唯一动作

人工审查 S6 report 与 Top/UART/XDC diff；确认后另起 S7 自检 TB + Vivado XSim gate。

## 最新 report 指针

- `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260719_205547_board_top_uart_integration_static_report.md`
