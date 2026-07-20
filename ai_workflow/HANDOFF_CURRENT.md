# 当前工程交接（下一位 agent 第一屏）

> 只放第一屏；唯一事实源 = 当前任务 `TASK_STATE.md`（纯快照，agent 专用）。
> 本文件每轮全量重写，硬上限 30 行。时间戳：20260719_183228

## 当前任务

20260717_multiboot_ctrl_fsm — Multiboot controller + ICAPE2 wrapper + Linux XSim/UNISIM。

## 关键现状（详见任务 TASK_STATE §2）

- 已实现 `multiboot_ctrl → multiboot_icape2_wrapper → ICAPE2`，抽象 controller 未绑定器件原语。
- wrapper 使用 X32 ICAPE2，实际写拍 `CSIB=0` / `RDWRB=0`，配置字逐 byte bit-reversal。
- 自检 TB 覆盖顺序/数量/物理数据、reset、busy 新请求、backpressure、UNISIM WBSTAR/IPROG 解码。
- 最终 run `20260719_024313_xsim-multiboot-ctrl`：`RESULT=PASS`，xelab 含 `unisims_ver.ICAPE2/SIM_CONFIGE2`。
- WDB：`_artifacts/common_vivado/20260719_024313_xsim-multiboot-ctrl/multiboot_ctrl.wdb`，44104 bytes。
- `_runs/latest` 与 `_artifacts/latest` 均指向该成功 run。
- 本轮仅梳理当前实现逻辑，未改 RTL/Tcl/TB、未运行 Vivado；`Top.v` 仍为空，Multiboot 未接入板级顶层。
- PASS 仅覆盖 ICAPE2 UNISIM 接口仿真，不覆盖 Flash 布局、地址编码、bitstream 或上板重配置。

## 下一步唯一动作

人工审查本轮逻辑梳理报告；确认后另起一轮定义 S5 Flash 模式/镜像布局/WBSTAR 编码与上板验证 gate。

## 最新 report 指针

- `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260719_183228_multiboot_logic_sortout_report.md`
