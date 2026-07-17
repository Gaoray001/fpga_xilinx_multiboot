# 当前工程交接（下一位 agent 第一屏）

> 只放第一屏；唯一事实源 = 当前任务 `TASK_STATE.md`（纯快照，agent 专用）。
> 本文件每轮全量重写，硬上限 30 行。时间戳：20260717_011642

## 当前任务

20260717_xsim_smoke_test — 建立最小 XSim 冒烟测试框架。

## 关键现状（详见任务 TASK_STATE §2）

- 已新增 `./scripts/vivado2018_common.sh xsim-smoke` 入口，映射 `tcl/sim/xsim_smoke.tcl`。
- 已新增独立 DUT `rtl/hdl/user/xsim_smoke_dut.v` 和 Verilog 自检 TB `sim/tb/tb_xsim_smoke.v`，TB 打印 `RESULT=PASS/FAIL`。
- 已真实运行 `./scripts/vivado2018_common.sh xsim-smoke`；成功 run = `20260717_011607_xsim-smoke`。
- `xsim_smoke_xsim.log` 含 `RESULT=PASS`；WDB 已生成：`_artifacts/common_vivado/20260717_011607_xsim-smoke/xsim_smoke.wdb`。
- 该 PASS 只覆盖最小 smoke DUT/TB，不覆盖 Multiboot 功能或上板行为。

## 下一步唯一动作

人工审查本任务 diff/report；若继续技术推进，另起一轮定义 Multiboot 功能级仿真目标。

## 插叙账（不改主线的支线轮在此各记一行；主线推进后清空）

（空）

## 最新 report 指针

- `reports/20260717_xsim_smoke_test_20260717_011642.md`
