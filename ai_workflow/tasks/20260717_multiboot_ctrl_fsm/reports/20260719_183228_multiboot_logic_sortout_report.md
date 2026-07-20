# 报告：Multiboot 当前实现逻辑梳理

- AI 模型类型：Codex / GPT-5 coding agent
- 时间戳：20260719_183228
- 本轮任务：读取并执行 `prompts/codex/004_multiboot_project_implementation_logic_sortout.md`
- 最终结论：本轮仅做实现逻辑梳理和状态同步；未修改 RTL/Tcl/TB，未运行 Vivado。

## git baseline

- branch：`dev`
- recent log：
  - `ff9adfc 增加multiboot原语ICAPE2`
  - `076720e 增加最小multiboot逻辑实现`
  - `e9a8047 Xsim冒烟测试-可观察vivado仿真波形`
  - `f8eb58d first commit`
- 开工 `git status --short`：

```text
?? prompts/codex/004_multiboot_project_implementation_logic_sortout.md
```

- 开工 `git diff --stat`：无 tracked diff。

## 输入事实摘要

- 前置任务已完成 `multiboot_ctrl -> multiboot_icape2_wrapper -> ICAPE2` 的 XSim/UNISIM 接口仿真，最终 `RESULT=PASS`。
- 本轮目标是说明当前工程已经实现了什么，重点回答顶层/子模块调用、数据走向、仿真对象与目的、下一步 gate 和上板编译时机。
- 本轮允许只读 shell/git 查询，并允许新增 report、更新 `ai_workflow` 状态文件。

## latest report 发现结果

- 开工时当前任务 `reports/` 实际最新文件为 `20260719_024339_multiboot_icape2_xsim_report.md`。
- prompt 指定的前置报告存在，且与实际 latest 一致。
- `TASK_INDEX.md` 没有独立“最新报告”字段；任务行指向 `TASK_STATE.md`。
- 本轮新报告为 `20260719_183228_multiboot_logic_sortout_report.md`。

## 边界自检

- WRITE_ALLOW / ALLOWLIST：允许更新 `multiboot/ai_workflow` 状态文件；允许新增当前任务 reports 下本报告。
- RUN_POLICY / COMMAND_ALLOW：R1；允许只读 git 查询、只读 shell 查询。
- COMMAND_DENY / HARD_BOUNDARY：未授权运行 EDA 工具、综合、实现、bitstream、上板、Flash 写入或修改 IP。
- OVERRIDE_BOUNDARY：无。
- 实际修改文件：本报告、`ai_workflow/HANDOFF_CURRENT.md`、`ai_workflow/TASK_INDEX.md`、`ai_workflow/tasks/20260717_multiboot_ctrl_fsm/TASK_STATE.md`。
- 实际运行命令：`sed`、`git branch --show-current`、`git status --short`、`git diff --stat`、`git log --oneline -5`、`find`、`rg --files`、`rg -n`、`date +%Y%m%d_%H%M%S`、`ls -l`。
- 是否触碰禁止项：no。
- 是否修改 hard-readonly 文件：no。
- 是否存在额外自主修改：no。
- 是否越界：no。

## 当前顶层、子模块、调用逻辑与数据走向

### 1. 工程顶层状态

- 工程默认综合顶层名仍是 `Top`，由 `scripts/vivado2018_common.sh` 默认导出 `COMMON_VIVADO_TOP_MODULE=Top`。
- 当前 `rtl/hdl/user/Top.v` 是 0 字节空文件，没有实例化 Multiboot controller，也没有接入板级时钟、复位、Flash、ICAP 仲裁、寄存器接口或触发源。
- 因此，当前 Multiboot 已实现的是“可仿真的局部重配置命令链路”，不是“已接入板卡顶层的完整上板功能”。

### 2. 仿真顶层状态

XSim 的实际顶层是 testbench：

```text
tb_multiboot_ctrl
  ├─ u_multiboot_ctrl
  └─ u_multiboot_icape2_wrapper
       └─ u_icape2 : UNISIM ICAPE2
            └─ SIM_CONFIGE2
```

Tcl 入口 `tcl/sim/xsim_multiboot_ctrl.tcl` 编译：

```text
rtl/hdl/user/multiboot/multiboot_ctrl.v
rtl/hdl/user/multiboot/multiboot_icape2_wrapper.v
sim/tb/tb_multiboot_ctrl.v
Vivado 2018.3 glbl.v
```

并在 `xelab` 中链接 `unisims_ver`，使 `ICAPE2` 和其内部 `SIM_CONFIGE2` 模型参与仿真。

### 3. `multiboot_ctrl` 的职责

`multiboot_ctrl` 是器件无关的抽象命令发生器。它只理解两个接口：

- 输入请求接口：`req_valid_i`、`req_ready_o`、`req_addr_i`。
- 输出命令流接口：`cmd_valid_o`、`cmd_ready_i`、`cmd_data_o`、`cmd_last_o`。

状态机逻辑：

```text
ST_IDLE
  - req_ready_o=1
  - 收到 req_valid_i && req_ready_o 后锁存 req_addr_i 到 target_addr_r
  - 进入 ST_SEND

ST_SEND
  - cmd_valid_o=1
  - 每次 cmd_valid_o && cmd_ready_i 成立发送一个 32-bit 配置字
  - 第 8 个 word fire 后进入 ST_DONE

ST_DONE
  - done_o 形成一个状态周期的完成指示
  - 下一拍回 ST_IDLE

ST_ERROR
  - 当前仅作为非法状态兜底
```

它发送的 8 个逻辑配置字为：

| index | 配置字 | 含义 |
|---:|---:|---|
| 0 | `FFFFFFFF` | dummy |
| 1 | `AA995566` | sync word |
| 2 | `20000000` | NOOP |
| 3 | `30020001` | write 1 word to WBSTAR |
| 4 | `req_addr_i` 锁存值 | WBSTAR payload |
| 5 | `30008001` | write 1 word to CMD |
| 6 | `0000000F` | IPROG command |
| 7 | `20000000` | trailing NOOP |

关键点：`req_addr_i` 当前被原样作为 WBSTAR payload，不等于已经完成 Flash byte address 到 WBSTAR 的板级编码。

### 4. `multiboot_icape2_wrapper` 的职责

`multiboot_icape2_wrapper` 是抽象命令流到 Xilinx 7 Series/Zynq-7000 `ICAPE2` 原语的适配层。

它做三件事：

1. 把 controller 的 `cmd_valid/cmd_ready/cmd_data` 转成 ICAPE2 写拍。
2. 对每个 32-bit 配置字按 byte 内 bit-reversal 转换为 ICAPE2 `I[31:0]` 物理数据。
3. 实例化 `ICAPE2 #(.ICAP_WIDTH("X32"), .SIM_CFG_FILE_NAME("NONE"))`。

握手与 ICAP 控制：

```text
cmd_ready_o = icap_enable_i && !R_gclk_100M_rst_i
cmd_fire_w  = cmd_valid_i && cmd_ready_o

cmd_fire_w=1  -> CSIB=0, RDWRB=0, I=bit_reversed(cmd_data_i)
cmd_fire_w=0  -> CSIB=1, RDWRB=0, I 仍由 cmd_data_i 组合得到但 ICAPE2 未选中
```

这里的 `icap_enable_i` 是外部授权/暂停入口，因为 ICAPE2 本身没有 ready 输出。系统集成时需要明确谁驱动它、何时允许写 ICAP、是否有其他 ICAP owner。

### 5. 数据走向

完整数据走向如下：

```text
外部触发源（当前未接入 Top）
  -> req_valid_i / req_addr_i
  -> multiboot_ctrl 锁存 target_addr_r
  -> 生成 8-word WBSTAR/IPROG 逻辑配置流
  -> cmd_valid_o / cmd_data_o / cmd_last_o
  -> multiboot_icape2_wrapper
  -> byte 内 bit-reversal
  -> ICAPE2.CSIB / ICAPE2.RDWRB / ICAPE2.I[31:0]
  -> UNISIM SIM_CONFIGE2 解码 WBSTAR 和 IPROG（仅仿真）
```

反压方向如下：

```text
icap_enable_i=0 或 reset=1
  -> wrapper cmd_ready_o=0
  -> controller 停在当前 cmd_index
  -> cmd_valid_o/cmd_data_o/cmd_last_o 保持
  -> ICAPE2.CSIB=1，不写入
```

## 仿真层对谁仿真？仿真的目的是什么？

### 仿真对象

当前 XSim 仿真对象不是 `Top.v`，而是局部 DUT 链：

```text
tb_multiboot_ctrl
  -> multiboot_ctrl
  -> multiboot_icape2_wrapper
  -> Vivado UNISIM ICAPE2 / SIM_CONFIGE2
```

也就是说，仿真覆盖的是“controller 到 ICAPE2 原语模型”的接口级行为，不覆盖板级集成。

### 仿真目的

仿真的目的是证明以下局部事实：

- controller 能在一次请求后输出固定 8-word WBSTAR/IPROG 序列。
- `cmd_ready_i` 反压时，controller 不丢 word、不重复 word、不改变当前 payload。
- busy 期间新 request 不会覆盖正在执行的 target address。
- reset 能中止执行中的命令流并回到空闲状态。
- wrapper 在写拍上驱动 `CSIB=0`、`RDWRB=0`。
- wrapper 对 `ICAPE2.I[31:0]` 做了每 byte bit-reversal。
- UNISIM `SIM_CONFIGE2` 能把写入序列解码为 `WBSTAR=0x00200000` 并观察到 IPROG pulse。

### 仿真不能证明的内容

当前仿真不能证明：

- `Top.v` 已完成板级接入。
- bitstream 可以综合/实现/timing clean。
- `req_addr_i` 是某种具体 SPI/BPI Flash 模式下正确的 WBSTAR 地址编码。
- Flash 镜像布局、golden/multiboot image offset、fallback 策略正确。
- 真实 FPGA 会重配置成功。
- Hardware Manager 可观测到上板行为。

因此，“ICAPE2 UNISIM PASS”只能表述为接口仿真通过，不能表述为上板 multiboot 已成功。

## 下一步应该推进什么？什么时候开始编译上板卡？

建议下一步不要直接编译上板卡。原因是当前缺少板级必需决策：

1. 精确目标器件型号与板卡配置模式。
2. Flash 类型、容量、地址宽度、SPI/BPI 模式和启动模式。
3. golden image 与 multiboot image 的 byte offset。
4. byte offset 到 WBSTAR payload 的编码规则。
5. `Top.v` 中 Multiboot 触发源、复位域、时钟域、ICAP owner/仲裁和状态观测接口。
6. ICAP 时钟约束与综合/实现时序边界。
7. 失败回退/fallback 策略和上板恢复方案。

推荐下一 gate：

```text
S5：Flash 模式/镜像布局/WBSTAR 编码定义 gate
  输出：地址编码说明 + 板级接入方案 + 上板验证/回滚计划

S6：板级 Top 集成 gate
  输出：Top 实例化、触发/状态接口、XDC/时钟约束、综合前静态审查

S7：首次综合/实现/bitstream gate
  前提：S5/S6 审查通过，且本轮明确授权运行 synth/impl/bit

S8：Flash 写入与 Hardware Manager 上板 gate
  前提：bitstream/MCS/BIN 生成策略、恢复手段、观测信号和回滚步骤已确认
```

开始编译上板卡的条件：

- 至少完成 S5 和 S6，并由人工明确授权“运行综合/实现/bitstream”。
- 在此之前，可以做代码审查、文档决策和板级接入设计，但不建议跑 full build 或生成 bitstream，因为即使编译通过也无法证明地址/Flash/回退策略正确。

## 修改摘要

- 新增本轮逻辑梳理报告。
- 更新 `TASK_STATE.md`：记录本轮 report-only 梳理事实与下一步。
- 更新 `HANDOFF_CURRENT.md`：下一位 agent 第一屏指向本轮报告与下一步。
- 更新 `TASK_INDEX.md`：任务下一步改为审查本轮逻辑梳理报告后进入 S5 定义。

## 实际改动文件

- `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260719_183228_multiboot_logic_sortout_report.md`（新增）
- `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/TASK_STATE.md`
- `ai_workflow/HANDOFF_CURRENT.md`
- `ai_workflow/TASK_INDEX.md`

## 额外自主修改说明

- 无目标外额外自主修改。
- 本轮没有修改 RTL/Tcl/TB；只更新允许范围内 workflow 状态与报告。

## 验证情况

- 已只读检查相关源码、testbench、Tcl 入口、Shell 入口和前置报告。
- 未运行 XSim/Vivado；本轮目标是逻辑梳理，且 prompt 只允许只读查询。

## 未执行事项

- 未修改 RTL、Tcl、XDC、Python、Shell。
- 未运行 Vivado、xvlog、xelab、xsim、综合、实现、bitstream。
- 未上板、未写 Flash、未发送真实 UDP 包。
- 未执行 git add/commit/push/reset/clean/stash。

## 风险与注意事项

- `Top.v` 为空文件；板级顶层集成仍未开始。
- 当前 `req_addr_i` 是 WBSTAR payload，不是已验证 Flash byte address API。
- `icap_enable_i` 的板级 owner/仲裁尚未定义。
- 前置 PASS 依赖 Vivado 2018.3 UNISIM 层次观测，不能外推为硬件重配置成功。
- 工作区存在未跟踪 prompt 文件；本轮未修改、未清理。

## 下一轮建议

- 人工先审查本报告是否准确表达当前实现。
- 下一轮建议开 S5：固定目标板卡/器件、配置模式、Flash 布局、WBSTAR 编码和上板回滚策略。
- S5 通过后再授权 `Top.v` 集成；板级集成审查通过后再进入综合/实现/bitstream。

## 待授权事项

- 修改 `Top.v` 接入 Multiboot 链路。
- 新增/修改 XDC 或 ICAP 时钟约束。
- 运行 Vivado synth/impl/bit。
- 生成 MCS/BIN、写 Flash、Hardware Manager 上板验证。

## FPGA 调试 yes/no 状态

- 是否修改 RTL：no。
- 是否修改 XDC：no。
- 是否修改 Tcl：no。
- 是否修改 Python：no。
- 是否运行 Vivado：no。
- 是否生成 bitstream：no。
- 是否上板：no。
- 是否发送真实 UDP 包：no。
- 是否修改 MIG/IP：no。

## 最终 git status --short

```text
 M ai_workflow/HANDOFF_CURRENT.md
 M ai_workflow/TASK_INDEX.md
 M ai_workflow/tasks/20260717_multiboot_ctrl_fsm/TASK_STATE.md
?? ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260719_183228_multiboot_logic_sortout_report.md
?? prompts/codex/004_multiboot_project_implementation_logic_sortout.md
```

## 最终 git diff --stat

```text
 ai_workflow/HANDOFF_CURRENT.md                              | 7 ++++---
 ai_workflow/TASK_INDEX.md                                   | 2 +-
 ai_workflow/tasks/20260717_multiboot_ctrl_fsm/TASK_STATE.md | 9 ++++++---
 3 files changed, 11 insertions(+), 7 deletions(-)
```
