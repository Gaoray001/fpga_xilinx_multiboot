# 20260717_multiboot_ctrl_fsm 任务验收标准（人工 2026-07-17 选定）

> hard-readonly：修改本文件须人工显式授权。验收以本轮 prompt 的 ACCEPTANCE 为准。

## 1. 抽象状态机

- `multiboot_ctrl` 能接收一次请求和目标地址，并在接受后锁存目标信息进入 busy。
- 通过抽象 command valid/ready 接口发送 Multiboot 命令序列。
- ready 拉低时当前命令保持稳定，不丢失、不重复、不乱序。
- 执行期间新请求不得破坏当前流程。
- 执行中复位能终止流程并回到 idle。
- 对外可观察 idle、busy、done、error 状态。

## 2. 功能级 XSim 仿真

- 存在 Verilog 自检 testbench，覆盖 prompt 的 FUNCTION_SCOPE 和 TEST_SCOPE。
- 存在统一 Shell 入口 `./scripts/vivado2018_common.sh xsim-multiboot-ctrl`。
- 已真实运行 XSim，最终日志明确包含 `RESULT=PASS` 或 `RESULT=FAIL`。
- 只有真实日志包含 `RESULT=PASS` 且产物完整，才可声称本轮抽象状态机仿真 PASS。

## 3. 产物与报告

- 成功运行后生成 WDB，并记录完整路径和文件大小。
- `_runs/latest` 指向最近一次运行目录。
- `_artifacts/latest` 只指向成功且产物完整的 artifact 目录，失败运行不得覆盖。
- 本轮报告写入 `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/`。

## 禁止结论（验收范围外，任何轮不得声称）

- 不得声称真实 ICAP 原语行为已验证。
- 不得声称 Flash 布局、Golden/Application 镜像或上板 Multiboot 已验证。
- 不得将 smoke test PASS 冒充为 Multiboot 功能级 PASS。
