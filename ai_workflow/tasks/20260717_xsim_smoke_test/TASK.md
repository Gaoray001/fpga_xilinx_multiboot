# XSim 冒烟测试框架任务（20260717_xsim_smoke_test）

> 稳定定义文件：目标 / 范围 / 绑定分支，进度与事实以本目录 `TASK_STATE.md` 为准。

## 1. 任务目标（人工确认：2026-07-17）

建立当前工程的最小、独立、自检型 XSim 冒烟测试框架，使后续具备以下基础调用链：

`Shell -> Tcl -> XSim -> Testbench -> PASS`

## 2. 绑定分支 / 基线

- 分支：`dev`。
- 基线 commit：`f8eb58d first commit`。

## 3. 范围（相关源码 / 工具）

- Shell 入口：`scripts/vivado2018_common.sh`。
- Tcl 仿真入口：`tcl/sim/xsim_smoke.tcl`。
- 最小测试对象：`rtl/hdl/user/xsim_smoke_dut.v`。
- 自检 testbench：`sim/tb/tb_xsim_smoke.v`。
- 仿真占位目录：`sim/xsim/`、`sim/wave/`。
- AI 工作流状态：`ai_workflow/tasks/20260717_xsim_smoke_test/`、`ai_workflow/HANDOFF_CURRENT.md`、`ai_workflow/TASK_INDEX.md`。
- 报告：`reports/*20260717_xsim_smoke_test*.md`。

## 4. 继承（只放指针，不复制内容）

- 本轮 prompt：`prompts/codex/001_build_minimal_runnable_xsim_smoke_test_framework.md`。
- 工程规则：`ai_workflow/AGENT_RULES.md`。

## 5. 任务级边界

- 不运行 Vivado。
- 不运行 `xvlog`、`xelab`、`xsim`。
- 不运行综合、实现或 bitstream 构建。
- 不上板、不下载 bit/ltx。
- 不修改现有 Multiboot 功能实现。
- 未有真实运行证据前，不得声称 XSim 已通过、仿真已 PASS、WDB 已成功生成。
