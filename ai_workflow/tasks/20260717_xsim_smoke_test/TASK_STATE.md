# 20260717_xsim_smoke_test 任务状态（纯快照）

> 本文件是本任务状态的唯一事实来源（SSOT），agent 专用；硬上限 150 行。
> 轮次历史 = 本任务 reports 指针 + git log。任务定义见 `TASK.md`；验收见 `ACCEPTANCE.md`。

## 1. 当前状态

- ACTIVE。阶段：S3 真实 XSim 冒烟验证已通过，等待人工审查 diff/report 并决定是否提交。
- 唯一下一步见 §6。

## 2. 关键事实（每条一行，证据 = report/commit 指针）

### 继承基线

- 分支 `dev`，基线 `f8eb58d first commit`；证据：`reports/20260717_xsim_smoke_test_20260717_010037.md`。
- 本任务 prompt 明确禁止调用 Vivado、`xvlog`、`xelab`、`xsim`、综合、实现、bitstream、git 写操作；证据：`prompts/codex/001_build_minimal_runnable_xsim_smoke_test_framework.md`。

### 本任务新增事实

- 已新增 Shell 入口 `./scripts/vivado2018_common.sh xsim-smoke`，映射到 `tcl/sim/xsim_smoke.tcl`；证据：`reports/20260717_xsim_smoke_test_20260717_010037.md`。
- 已新增独立 smoke DUT `rtl/hdl/user/xsim_smoke_dut.v` 和自检 testbench `sim/tb/tb_xsim_smoke.v`；testbench 输出 `RESULT=PASS` 或 `RESULT=FAIL`；证据：`reports/20260717_xsim_smoke_test_20260717_010037.md`。
- Tcl 入口 `tcl/sim/xsim_smoke.tcl` 已改为通过 Tcl `exec` 调用外部 `xvlog`、`xelab`、`xsim`；证据：`reports/20260717_xsim_smoke_test_20260717_011642.md`。
- 首次真实运行 `20260717_011503_xsim-smoke` 失败，原因是 Tcl 将 `xvlog` 当作 Vivado Tcl 内建命令；证据：`reports/20260717_xsim_smoke_test_20260717_011642.md`。
- 第二次真实运行 `20260717_011607_xsim-smoke` 成功，`summary.txt` 为 `result: SUCCESS`，`xsim_smoke_xsim.log` 含 `RESULT=PASS`；证据：`reports/20260717_xsim_smoke_test_20260717_011642.md`。
- 已生成 WDB：`_artifacts/common_vivado/20260717_011607_xsim-smoke/xsim_smoke.wdb`，大小 9879 bytes；证据：`reports/20260717_xsim_smoke_test_20260717_011642.md`。

## 3. 阶段门（每 gate 一行：Planned / In Progress / Done）

- S0 Done — 任务初始化与边界登记。
- S1 Done — 最小 XSim 冒烟测试文件和 Shell/Tcl 调用入口建立。
- S2 Done — Linux Vivado/XSim 环境运行 `./scripts/vivado2018_common.sh xsim-smoke` 成功。
- S3 Done — 根据真实运行日志和 WDB 产物更新验收与报告。

## 4. 证据边界 / 禁止误称

- 静态检查通过不等于 XSim 运行通过。
- 本任务已有一次真实 `xsim-smoke` PASS 证据；该结论仅覆盖最小 smoke DUT/testbench，不覆盖 Multiboot 功能正确性。
- WDB 已生成的结论仅覆盖 `20260717_011607_xsim-smoke` 运行产物。
- 未上板不得声称板级行为正确。

## 5. 待补证据 / 待决策 / 待授权

- 人工审查本任务 diff/report 后决定是否提交。
- 后续若扩展到 Multiboot 功能验证，需要单独授权新的 testbench/验收口径。

## 6. 唯一下一步

人工审查本任务 diff/report；若继续技术推进，另起一轮定义 Multiboot 功能级仿真目标。

## 7. 仓库要点

- 分支 `dev`，基线 `f8eb58d first commit`。
- hard-readonly = `ai_workflow/AGENT_RULES.md` / 已存在任务的 `ACCEPTANCE.md`；本任务 `ACCEPTANCE.md` 为本轮按 prompt 新建。
- 开工前已有脏改动：`scripts/vivado2018_common.sh` usage 默认 part name 变更；未跟踪 `constraints/PIN.xdc`、`docs/xilinx_fpga_multiboot.drawio`、`prompts/codex/`、空文件 `rtl/hdl/user/Top.v`、`rtl/hdl/user/multiboot/multiboot_ctrl.v`、`sim/tb/tb_multiboot_ctrl.v`、`scripts/open_latest_gui.sh`；本轮不清理、不回滚。
