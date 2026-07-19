 
# Agent Task Prompt

执行 `ai_workflow/AGENT_RULES.md`。本轮只填写差量。

## FACT:

```text
- 当前分支：dev
- 当前工程路径：/data/work/fpga/multiboot
- 当前工程主线：开发 Xilinx FPGA Multiboot 功能，并同步完善 AI + FPGA 开发工作流
- Linux 服务器作为主要开发、构建和仿真平台
- Windows Vivado Hardware Manager 用于 bit/ltx 下载和板卡调试
- 最小 XSim 冒烟测试已经真实运行通过
- 当前调用链已经验证：
  Shell → Tcl → xvlog → xelab → xsim → Testbench → RESULT=PASS
- 当前已经能够生成并使用 Vivado 打开 WDB 波形
- 当前已有：
  - rtl/hdl/user/multiboot/
  - sim/tb/tb_multiboot_ctrl.v
  - sim/xsim/
  - sim/wave/
  - tcl/sim/
  - scripts/vivado2018_common.sh
- `_runs/latest` 已作为最近一次运行目录入口
- 当前尚未建立 `_artifacts/latest`
- 当前尚未完成抽象 Multiboot 状态机的功能级仿真闭环
```

## GOAL:

```text
总目标：

推进抽象 Multiboot 状态机实现，并建立对应的 Linux XSim 功能级仿真闭环。

本轮目标：

1. 审查当前 Multiboot 相关 RTL、Testbench、Tcl 和 Shell 入口。

2. 实现或完善抽象 Multiboot 状态机。

3. 状态机应面向抽象 ICAP 发送接口，不在本轮绑定具体 FPGA 配置原语。

4. 建立状态机的自检型 Testbench。

5. 建立统一 Shell 仿真入口，实际运行 XSim 功能级仿真。

6. 仿真必须输出明确的：
   - RESULT=PASS
   - 或 RESULT=FAIL

7. 生成可通过 Vivado Waveform 查看状态机行为的 WDB。

8. 建立 `_artifacts/latest` 链接：
   - 指向最近一次成功且产物完整的 artifact 目录
   - 失败运行不得覆盖已有 `_artifacts/latest`
   - 不改变 `_runs/latest` 的现有语义

9. 落地任务报告默认规则：
   - 未经用户另行指定时，报告默认放在当前任务目录的 `reports/`
   - 文件名格式为 `<TS>_<agent自行命名>.md`
   - `<TS>` 使用工程当前统一时间戳格式
   - Agent 根据报告实际内容自行确定文件名主题
   - 不再默认写入工程根目录下的 `reports/`

10. 创建并更新本轮 AI 工作流任务文件和状态文件。
```

## WRITE_ALLOW:

```text
- rtl/hdl/user/multiboot/**

- sim/tb/tb_multiboot_ctrl.v
- sim/tb/**multiboot**
- sim/xsim/**
- sim/wave/**

- tcl/sim/**

- scripts/vivado2018_common.sh
- scripts/open_latest_gui.sh
- scripts/**multiboot**

- ai_workflow/AGENT_RULES.md
- ai_workflow/HANDOFF_CURRENT.md
- ai_workflow/TASK_INDEX.md
- ai_workflow/templates/**
- ai_workflow/tasks/20260717_multiboot_ctrl_fsm/**

- _artifacts/latest
```

## PREFERENCE:

```text
- 保持当前工程目录结构，不进行无关重构。
- Testbench 使用 Verilog，不使用 SystemVerilog。
- 仿真采用 XSim，不引入 ModelSim 或 Questa。
- Testbench 必须自检，波形只用于定位和人工分析。
- 抽象控制逻辑与器件专用 ICAP 原语保持分离。
- Shell、Tcl、RTL、Testbench 各自保持职责边界。
- 优先复用现有 XSim 冒烟测试调度方式。
- 优先在现有文件基础上增量修改。
- 不为后续 UDP 接入、Flash 镜像布局或器件专用封装提前扩展框架。
- 不预设不必要的状态名称、代码结构或内部实现方式。
- 不移动或重命名既有历史报告。
- 报告使用中文。
- 代码、脚本和报告应便于后续人工理解与 Agent 接力。
```

## RUN_POLICY:

```text
R2：可运行且可修改。

允许：
- 修改 WRITE_ALLOW 范围内的文件
- 新增本轮任务文件和报告
- 运行 Shell 静态检查
- 运行 Tcl/文本/路径静态检查
- 运行 Multiboot 状态机的 XSim 功能级仿真
- 根据真实仿真结果修复 RTL、Testbench、Tcl 或 Shell
- 多次运行仿真直至得到明确结果
- 生成日志和 WDB
- 成功后更新 `_artifacts/latest`
- 更新 AI 工作流状态文件

不允许：
- 运行综合
- 运行实现
- 生成 bitstream
- 写入 Flash
- 上板
- 发送真实 UDP 数据
```

## HARD_BOUNDARY:

```text
- 不执行 git add。
- 不执行 git commit。
- 不执行 git push。
- 不切换分支。
- 不修改 WRITE_ALLOW 之外的文件。
- 不实例化或接入 ICAPE2、ICAPE3 等器件专用原语。
- 不实现 UDP 命令解析或 UDP 协议栈接入。
- 不确定正式 Flash 地址布局。
- 不生成 Golden/Application 双镜像。
- 不实现上板重配置。
- 不修改现有 synth、impl、bit、full 的功能语义。
- 不因仿真通过而声明真实 FPGA Multiboot 已通过。
- 不将最小 XSim 冒烟测试结果冒充为 Multiboot 功能级结果。
- 不覆盖或清理本轮开始前已有的用户改动。
- 仿真失败时不得将 `_artifacts/latest` 指向失败运行。
```

## FUNCTION_SCOPE:

```text
本轮抽象 Multiboot 状态机应至少支持以下外部行为：

1. 接收一次 Multiboot 请求及其目标地址。

2. 请求被接受后，锁存本次目标信息并进入忙状态。

3. 通过抽象发送接口输出 Multiboot 所需命令序列。

4. 抽象发送接口存在未就绪情况时：
   - 当前待发送内容保持稳定
   - 状态机不跳过该内容
   - 恢复就绪后继续执行

5. 执行期间的新请求不得破坏当前请求。

6. 复位后返回初始状态，并停止未完成的发送过程。

7. 对外提供足以判断状态机：
   - 空闲
   - 正在执行
   - 完成
   - 错误
   的可观察状态。

8. 本轮只验证抽象命令序列和控制行为，不验证真实 FPGA 重配置。
```

## TEST_SCOPE:

```text
Testbench 至少验证：

1. 正常 Multiboot 请求能够完成预期抽象命令发送。

2. 目标地址能够在发送过程中保持正确。

3. 抽象发送接口持续就绪时，正常流程能够结束。

4. 抽象发送接口间歇性未就绪时：
   - 数据不丢失
   - 数据不重复
   - 顺序不被破坏

5. 执行期间再次输入请求时，当前流程不被覆盖或重新启动。

6. 执行过程中复位时，状态机能够终止当前流程并回到初始状态。

7. Testbench 对实际发送内容、数量和顺序进行自动检查。

8. 所有测试通过时输出：
   RESULT=PASS

9. 任一检查失败时：
   - 输出清晰的错误信息
   - 增加错误计数
   - 最终输出 RESULT=FAIL
   - 仿真进程返回非成功结果，或由外层脚本可靠判定失败
```

## ARTIFACT_POLICY:

```text
1. `_runs/latest`：

   表示最近一次运行目录，保持当前已有行为。

2. `_artifacts/latest`：

   表示最近一次成功且产物完整的 artifact 目录。

3. 只有同时满足以下条件才允许更新 `_artifacts/latest`：
   - Shell/Tcl 调用成功
   - XSim 编译和 elaboration 成功
   - Testbench 输出 RESULT=PASS
   - 本轮要求的日志和 WDB 已生成
   - 目标 artifact 目录存在

4. 失败时：
   - 保留失败运行日志
   - 保留原有 `_artifacts/latest`
   - 不创建指向不存在目录的链接

5. 最终报告记录：
   - `_runs/latest` 实际目标
   - `_artifacts/latest` 实际目标
   - 两者是否指向同一轮运行
   - `_artifacts/latest` 是否在本轮更新
```

## REPORT_POLICY:

```text
1. 本轮任务目录：

   ai_workflow/tasks/20260717_multiboot_ctrl_fsm/

2. 本轮报告默认目录：

   ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/

3. 报告文件名：

   <TS>_<agent自行命名>.md

4. Agent 应根据报告实际内容自行选择简洁、准确的报告主题。

5. 除非用户明确指定其他位置，不得将本轮报告默认写入：

   reports/

6. 将该默认报告规则同步到适合长期约束的位置。

7. 不批量迁移或整理历史报告。
```

## ACCEPTANCE:

```text
1. 已创建或更新：

   - ai_workflow/tasks/20260717_multiboot_ctrl_fsm/TASK.md
   - ai_workflow/tasks/20260717_multiboot_ctrl_fsm/TASK_STATE.md
   - ai_workflow/tasks/20260717_multiboot_ctrl_fsm/ACCEPTANCE.md
   - ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/<TS>_<agent自行命名>.md

2. 已更新：

   - ai_workflow/HANDOFF_CURRENT.md
   - ai_workflow/TASK_INDEX.md

3. 已在适合长期约束的位置写明默认报告路径和文件命名规则。

4. 抽象 Multiboot 状态机已经实现或完善。

5. 未在抽象状态机中绑定 ICAPE2、ICAPE3 或其他器件专用原语。

6. 已建立自检型 Verilog Testbench。

7. Testbench 覆盖 FUNCTION_SCOPE 和 TEST_SCOPE 中的要求。

8. 已建立统一 Shell 仿真入口。

9. 已真实运行 XSim 功能级仿真。

10. 最终日志包含真实的：
    RESULT=PASS
    或
    RESULT=FAIL

11. 只有真实通过时，才允许声称本轮 Multiboot 抽象状态机仿真 PASS。

12. 真实通过时已生成 WDB，并记录其完整路径和文件大小。

13. `_runs/latest` 可以定位最近一次运行。

14. `_artifacts/latest` 已建立，并只指向成功且产物完整的 artifact 目录。

15. 若最后一次运行失败：
    - `_runs/latest` 可指向失败运行
    - `_artifacts/latest` 必须保持指向上一次成功运行

16. 已执行并记录：
    - bash 语法检查
    - git diff --check
    - 实际 XSim 运行命令
    - PASS/FAIL 日志证据
    - WDB 文件证据
    - latest 链接检查

17. 未运行综合、实现或 bitstream。

18. 未执行任何 git 写操作。

19. 最终报告明确区分：
    - 抽象状态机仿真结果
    - 尚未验证的真实 ICAP、Flash 和上板 Multiboot 行为
```

## FINAL_REPORT:

```text
最终报告至少包含：

- AI 模型类型
- 本轮任务
- git baseline
- 输入事实摘要
- 边界自检
- 实际修改文件
- 状态机外部行为说明
- Testbench 测试项
- Shell/Tcl/XSim 调用链
- 实际运行命令
- 首次运行结果
- 修复过程
- 最终运行结果
- RESULT=PASS/FAIL 证据
- WDB 路径和文件大小
- `_runs/latest` 指向
- `_artifacts/latest` 指向
- 报告规则落地位置
- 未执行事项
- 风险与注意事项
- 下一轮建议
- FPGA 调试 yes/no 状态
- 最终 git status --short
- 最终 git diff --stat
```