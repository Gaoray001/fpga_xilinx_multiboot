# Agent Task Prompt

执行 `ai_workflow/AGENT_RULES.md`。本轮只填写差量。

## FACT:

```text
- 当前分支：dev
- 当前工程路径：/data/work/fpga/multiboot
- 当前工程主线：开发 Xilinx FPGA Multiboot 功能，并同步完善 AI + FPGA 开发工作流
- 当前工程已经具备：
  - scripts/vivado2018_common.sh
  - tcl/build/
  - sim/tb/
  - ai_workflow/
  - reports/
- Linux 服务器作为后续主要开发、构建和仿真平台
- Windows Vivado Hardware Manager 用于 bit/ltx 下载和板卡调试
- 当前尚未建立最小 XSim 冒烟测试闭环
```

## GOAL:

```text
总目标：

建立当前工程的最小 XSim 冒烟测试，使工程具备后续验证以下调用链的基础：

Shell → Tcl → XSim → Testbench → PASS

本轮目标：

1. 在当前工程中建立最小、独立、自检型的 XSim 冒烟测试。

2. 为现有脚本体系增加明确的仿真调用入口，使后续能够通过统一 Shell 入口发起冒烟测试。

3. 建立仿真所需的 Tcl、RTL/Testbench 和结果判定基础。

4. 冒烟测试应具备明确的 PASS/FAIL 输出，不以人工查看波形作为唯一验收方式。

5. 保持当前工程已有目录分层，不重构与本任务无关的构建流程。

6. 新增一份 Linux 仿真指导说明报告，说明：
   - 本次新增内容
   - Shell、Tcl、XSim、Testbench 之间的调用关系
   - 后续实际运行命令
   - 仿真输出及 PASS/FAIL 的查看方法
   - WDB 波形文件的生成与查看方式
   - 当前未执行的验证项及后续验证步骤

7. 更新本任务对应的 AI 工作流状态文件。
```

## WRITE_ALLOW:

```text
- scripts/vivado2018_common.sh

- tcl/sim/**

- sim/tb/**
- sim/xsim/**
- sim/wave/**

- rtl/hdl/user/**
  仅允许增加最小冒烟测试确有必要的测试对象。
  不修改现有 Multiboot 功能实现。

- reports/**

- ai_workflow/HANDOFF_CURRENT.md
- ai_workflow/TASK_INDEX.md
- ai_workflow/tasks/20260717_xsim_smoke_test/**
```

## PREFERENCE:

```text
- 优先保持实现最小化。
- Testbench 使用 Verilog，不使用 SystemVerilog。
- 冒烟测试应为自检型测试。
- 测试结果必须输出明确的 RESULT=PASS 或 RESULT=FAIL。
- Shell、Tcl、Testbench 各自保持职责边界。
- 不为后续 Multiboot RTL 提前设计功能接口。
- 不加入与本轮冒烟测试无关的通用框架。
- 不引入 ModelSim、Questa 或其他仿真器。
- 不修改现有 build、synth、impl、bit、full 构建行为。
- 指导说明报告使用中文。
- 脚本和代码中的关键信息应便于后续人工理解和 Agent 复用。
```

## RUN_POLICY:

```text
R2：可修改、可新增。

允许：
- 新增和修改本轮允许范围内的脚本
- 新增 Tcl 仿真入口
- 新增最小 RTL/Testbench
- 新增指导说明报告
- 新增或更新 AI 工作流状态文件
- 执行不调用 Vivado 的静态检查
- 执行 shell 语法检查
- 执行文件存在性、路径和文本检查

不允许：
- 调用 Vivado
- 调用 xvlog、xelab、xsim
- 启动实际仿真
- 启动综合、实现或 bitstream 构建
```

## HARD_BOUNDARY:

```text
- 不运行 Vivado。
- 不运行 XSim。
- 不运行综合、实现或 bitstream。
- 不执行 git add。
- 不执行 git commit。
- 不执行 git push。
- 不切换分支。
- 不修改 WRITE_ALLOW 之外的文件。
- 不修改现有 Multiboot RTL 功能。
- 不顺带处理旧工程迁移、Flash 布局、ICAP 命令或 UDP 接口。
- 不以本轮未实际运行的结果声明 XSim 已经验证通过。
```

## ACCEPTANCE:

```text
1. 已建立最小 XSim 冒烟测试所需的文件和调用入口。

2. Shell 入口、Tcl 仿真入口、Testbench 和测试对象之间的调用关系清晰。

3. Testbench 为 Verilog 自检型测试，具备明确的：
   - RESULT=PASS
   - RESULT=FAIL

4. 仿真入口具备后续生成日志和 WDB 波形文件的基础。

5. 现有 build、synth、impl、bit、full 流程未被破坏或改变。

6. 对新增或修改的 Shell 脚本完成语法检查。

7. 未调用 Vivado、xvlog、xelab 或 xsim。

8. 新增 Linux XSim 仿真指导说明报告，报告至少包含：
   - 任务目标
   - 新增和修改文件清单
   - 调用链说明
   - 后续实际运行命令
   - PASS/FAIL 判断方法
   - 日志及 WDB 波形查看方法
   - 本轮未执行事项
   - 下一轮建议验证步骤

9. 创建或更新：
   - ai_workflow/tasks/20260717_xsim_smoke_test/TASK.md
   - ai_workflow/tasks/20260717_xsim_smoke_test/TASK_STATE.md
   - ai_workflow/tasks/20260717_xsim_smoke_test/ACCEPTANCE.md
   - ai_workflow/HANDOFF_CURRENT.md
   - ai_workflow/TASK_INDEX.md

10. 最终报告必须明确区分：
    - 已完成的文件与静态检查
    - 尚未执行的实际 XSim 验证

11. 最终不得写成：
    - XSim 已通过
    - 仿真已 PASS
    - WDB 已成功生成

    除非存在本轮允许范围内的真实执行证据；当前硬边界下应记录为待验证。
```

## REPORT:

```
在 reports/ 下新增本轮报告，文件名包含：

20260717_xsim_smoke_test

报告应基于实际修改和静态检查结果填写，不推测实际 Vivado/XSim 运行结果。
```