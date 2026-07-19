# Multiboot 抽象状态机功能仿真任务（20260717_multiboot_ctrl_fsm）

> 稳定定义文件：目标 / 范围 / 绑定分支，进度与事实以本目录 `TASK_STATE.md` 为准。

## 1. 任务目标（人工确认：2026-07-17）

实现抽象 Multiboot 控制状态机，并建立 Linux XSim 功能级仿真闭环：

`Shell -> Tcl -> xvlog -> xelab -> xsim -> Testbench -> RESULT=PASS/FAIL`

## 2. 绑定分支 / 基线

- 分支：`dev`。
- 基线 commit：`e9a8047 Xsim冒烟测试-可观察vivado仿真波形`。

## 3. 范围（相关源码 / 工具）

- RTL：`rtl/hdl/user/multiboot/multiboot_ctrl.v`。
- Testbench：`sim/tb/tb_multiboot_ctrl.v`。
- Tcl 仿真入口：`tcl/sim/xsim_multiboot_ctrl.tcl`。
- Shell 入口：`scripts/vivado2018_common.sh xsim-multiboot-ctrl`。
- 产物 latest：`_runs/latest`、`_artifacts/latest`。
- 工作流：`ai_workflow/tasks/20260717_multiboot_ctrl_fsm/`、`ai_workflow/HANDOFF_CURRENT.md`、`ai_workflow/TASK_INDEX.md`。

## 4. 继承（只放指针，不复制内容）

- 本轮 prompt：`prompts/codex/002_build_corresponding_linux_xsim_functional_simulation_closed_loop.md`。
- 前置 smoke 任务：`ai_workflow/tasks/20260717_xsim_smoke_test/TASK_STATE.md`。

## 5. 任务级边界

- 不实例化或接入 ICAPE2、ICAPE3 等器件专用原语。
- 不实现 UDP 命令解析或 UDP 协议栈接入。
- 不确定正式 Flash 地址布局。
- 不生成 Golden/Application 双镜像。
- 不实现上板重配置。
- 不因仿真通过而声明真实 FPGA Multiboot 已通过。
