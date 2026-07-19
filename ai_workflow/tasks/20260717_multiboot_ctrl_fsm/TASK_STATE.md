# 20260717_multiboot_ctrl_fsm 任务状态（纯快照）

> 本文件是本任务状态的唯一事实来源（SSOT），agent 专用；硬上限 150 行。
> 轮次历史 = 本目录 `reports/` + git log。任务定义见 `TASK.md`；验收见 `ACCEPTANCE.md`。

## 1. 当前状态

- ACTIVE。阶段：S3 抽象 Multiboot 状态机 XSim 功能仿真已 PASS，等待人工审查 diff/report。
- 唯一下一步见 §6。

## 2. 关键事实（每条一行，证据 = report/commit 指针）

### 继承基线

- 分支 `dev`，基线 `e9a8047 Xsim冒烟测试-可观察vivado仿真波形`；证据：本轮报告。
- 前置 smoke 调用链已真实通过；证据：`ai_workflow/tasks/20260717_xsim_smoke_test/TASK_STATE.md`。

### 本任务新增事实

- 已实现抽象 `multiboot_ctrl` FSM，外部为请求接口 + 抽象 command valid/ready 接口，未实例化 ICAP 原语；证据：`reports/20260717_021312_multiboot_ctrl_fsm_xsim_report.md`。
- 已实现 Verilog 自检 TB，覆盖连续 ready、间歇 backpressure、busy 期间新请求、执行中 reset；证据：`reports/20260717_021312_multiboot_ctrl_fsm_xsim_report.md`。
- 已新增 Shell 入口 `./scripts/vivado2018_common.sh xsim-multiboot-ctrl` 和 Tcl 入口 `tcl/sim/xsim_multiboot_ctrl.tcl`；证据：`reports/20260717_021312_multiboot_ctrl_fsm_xsim_report.md`。
- 真实运行 `20260717_021704_xsim-multiboot-ctrl` 成功，`multiboot_ctrl_xsim.log` 含 `RESULT=PASS`；证据：`reports/20260717_021312_multiboot_ctrl_fsm_xsim_report.md`。
- 已生成 WDB：`_artifacts/common_vivado/20260717_021704_xsim-multiboot-ctrl/multiboot_ctrl.wdb`，大小 29894 bytes；证据：`reports/20260717_021312_multiboot_ctrl_fsm_xsim_report.md`。
- `_runs/latest` 和 `_artifacts/latest` 均指向 `common_vivado/20260717_021704_xsim-multiboot-ctrl`；证据：`reports/20260717_021312_multiboot_ctrl_fsm_xsim_report.md`。
- 报告默认路径规则已同步到 `ai_workflow/AGENT_RULES.md` 和 `ai_workflow/templates/report_template.md`；证据：`reports/20260717_021312_multiboot_ctrl_fsm_xsim_report.md`。

## 3. 阶段门（每 gate 一行：Planned / In Progress / Done）

- S0 Done — 任务初始化与边界登记。
- S1 Done — 抽象 FSM / TB / Tcl / Shell 入口实现。
- S2 Done — Linux XSim 功能级仿真运行通过。
- S3 Done — latest 链接、状态和报告收口。

## 4. 证据边界 / 禁止误称

- 本任务只验证抽象状态机和抽象命令流。
- 本任务已有一次真实 `xsim-multiboot-ctrl` PASS 证据。
- 不验证真实 ICAP 原语、Flash 布局、Golden/Application 镜像或上板 Multiboot。
- `_artifacts/latest` 只能指向成功且产物完整的 artifact 目录。

## 5. 待补证据 / 待决策 / 待授权

- 人工审查本任务 diff/report 后决定是否提交。
- 后续若要接入真实 ICAP、Flash 布局或上板 Multiboot，需要单独授权和验收口径。

## 6. 唯一下一步

人工审查本任务 diff/report；若继续推进，另起一轮定义真实 ICAP/Flash/上板边界或更高层功能仿真目标。

## 7. 仓库要点

- 开工时工作区仅有未跟踪 prompt：`prompts/codex/002_build_corresponding_linux_xsim_functional_simulation_closed_loop.md`。
- 本轮不执行 git add/commit/push，不切换分支，不清理未跟踪文件。
