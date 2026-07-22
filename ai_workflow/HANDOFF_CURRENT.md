# 当前工程交接（下一位 agent 第一屏）

> 只放第一屏；唯一事实源 = 当前任务 `TASK_STATE.md`（纯快照，agent 专用）。
> 本文件每轮全量重写，硬上限 30 行。时间戳：20260720_021049

## 当前任务

20260717_multiboot_ctrl_fsm — S9 上板验证指导与 latest WDB 打开脚本完成。

## 关键现状（详见任务 TASK_STATE §2）

- Top 链路：UART RX → `uart_boot_trigger` → `multiboot_ctrl` → `multiboot_icape2_wrapper` → `ICAPE2`。
- Golden offset/WBSTAR=`0x00000000`；Application offset/WBSTAR=`0x00800000`。
- UART 命令：`BOOT APP\r\n` / `BOOT GOLDEN\r\n`；ACK `0x06` 后发 multiboot request。
- S7/S8 XSim latest `20260719_235747_xsim-top-uart-multiboot`：`RESULT=PASS`，WDB 660151 bytes。
- 人工 full build 已生成 bit；只读核对 `_runs/latest -> common_vivado/20260720_014923_full`。
- `Top.bit` 位于 `_artifacts/common_vivado/20260720_014923_full/Top.bit`，2192126 bytes。
- `impl_timing_summary.rpt`：timing met，WNS 14.220 ns；`impl_drc.rpt`：0 violations。
- 当前只看到单个 `Top.bit`；未看到 Golden/App 两个 bit 或合并 MCS，不能声称 Flash multiboot 已验证。
- 新增 `scripts/open_latest_wbd.sh`：打开 `_artifacts/latest/*.wdb`，当前 `_artifacts/latest` 仍指向 XSim WDB。
- 本轮未运行 Vivado/Hardware Manager，未生成/烧录 MCS，未上板。

## 下一步唯一动作：人工按 S9 report 执行/审查上板验证；回传 bit/MCS/Flash/UART/LED 证据后另起 S10 收口 gate。

## 最新 report 指针

- `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260720_021049_multiboot_board_verify_guidance_report.md`
