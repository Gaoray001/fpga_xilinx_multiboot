# 20260717_xsim_smoke_test 任务验收标准（人工 2026-07-17 选定）

> hard-readonly：修改本文件须人工显式授权。验收以本轮 prompt 的 ACCEPTANCE 为准。

## 1. 最小冒烟测试框架

- 存在 Shell 入口、Tcl 仿真入口、最小 DUT、Verilog 自检 testbench。
- 调用链清晰：`Shell -> Tcl -> XSim -> Testbench -> PASS/FAIL`。
- Testbench 明确输出 `RESULT=PASS` 或 `RESULT=FAIL`。

## 2. 静态检查

- 对新增或修改的 Shell 脚本完成语法检查。
- 对新增 Tcl/RTL/Testbench 做文件存在性、路径和文本检查。
- 不调用 Vivado、`xvlog`、`xelab`、`xsim`。

## 3. 报告与状态

- 新增中文 Linux XSim 仿真指导说明报告，包含新增内容、调用链、后续运行命令、PASS/FAIL 判断、日志及 WDB 查看方法、未执行事项和下一轮建议。
- 更新 `TASK.md`、`TASK_STATE.md`、`ACCEPTANCE.md`、`HANDOFF_CURRENT.md`、`TASK_INDEX.md`。

## 禁止结论（验收范围外，任何轮不得声称）

- 未真实运行 XSim，不得声称 XSim 已通过或仿真已 PASS。
- 未真实生成 `.wdb` 文件，不得声称 WDB 已成功生成。
- 未上板，不得声称板级行为正确。
