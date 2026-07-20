# 报告：Top/UART 集成逻辑与 Testbench 安排说明

- AI 模型类型：Codex / GPT-5 coding agent
- 时间戳：20260720_003126
- 本轮任务：读取并执行 `prompts/codex/008_multiboot_new_top_uart_integrated_selftest_testbench_arrange.md`
- 本轮性质：S8 逻辑梳理 / testbench 安排说明
- 最终结论：已梳理当前 Top、子模块调用关系、数据走向、XSim 仿真对象、testbench 激励方式和推进下一阶段的理想观测判据；本轮未修改 RTL/TB/Tcl/XDC，未运行 Vivado。

## 1. git baseline

- branch：`dev`
- baseline commit：`6afa7db 增加top触发源+multiboot逻辑+vivado仿真`
- recent log：
  - `6afa7db 增加top触发源+multiboot逻辑+vivado仿真`
  - `3ebbc88 增加uart触发源+multiboot逻辑-未上板卡验证`
  - `9dc8ee4 硬件板卡边界确定+Top板级实现方案规划`
  - `27bbdef 增加multiboot逻辑实现理解`
  - `ff9adfc 增加multiboot原语ICAPE2`
- 开工 `git status --short --untracked-files=all`：

```text
?? prompts/codex/008_multiboot_new_top_uart_integrated_selftest_testbench_arrange.md
```

- 开工 `git diff --stat`：空。

## 2. 输入事实摘要

- 活跃任务：`ai_workflow/tasks/20260717_multiboot_ctrl_fsm`。
- 前置报告：`reports/20260719_232416_top_uart_xsim_report.md`。
- 目标平台：Xilinx 7 Series / Zynq-7000 PL 侧 ICAP，使用 `ICAPE2`。
- 本轮目标：解释当前工程已实现的逻辑，让人能理解顶层/子模块/仿真/testbench/推进判据。
- Linux 用于 RTL 开发和 XSim；Windows Hardware Manager 后续上板使用。

## 3. latest report 与运行产物发现

- 当前任务 `reports/` 目录开工实际最新文件：`20260719_232416_top_uart_xsim_report.md`，与 008 prompt 指定前置报告一致。
- git 最新 commit `6afa7db` 已包含 S7 report、prompt、TB/Tcl/Shell 和状态更新；因此开工工作区只剩 008 prompt 未跟踪。
- `TASK_STATE.md` 原记录的 S7 成功 run 是 `20260719_232340_xsim-top-uart-multiboot`。
- 只读核对发现当前 `_runs/latest` / `_artifacts/latest` 已指向更晚的 `20260719_235747_xsim-top-uart-multiboot`。
- `20260719_235747_xsim-top-uart-multiboot` 状态为 `SUCCESS`，日志含 `RESULT=PASS`，WDB 为 `_artifacts/common_vivado/20260719_235747_xsim-top-uart-multiboot/top_uart_multiboot.wdb`，660151 bytes。

## 4. 边界自检

- WRITE_ALLOW：允许更新 `ai_workflow` 状态文件；允许新增本任务 reports。
- RUN_POLICY：R1；允许 git 查询只读类命令，允许 shell 查询只读类命令。
- HARD_BOUNDARY：允许新增报告；允许更新 `ai_workflow` 下状态文件。
- OVERRIDE_BOUNDARY：未提供。
- 实际修改：新增本报告，更新 `TASK_STATE.md`、`HANDOFF_CURRENT.md`、`TASK_INDEX.md`。
- 实际只读命令：`sed`、`rg`、`ls`、`readlink`、`date`、`git branch/status/diff/log/show`。
- 未运行 Vivado、未运行综合/实现/bitstream、未上板。
- 未修改 RTL/TB/Tcl/XDC/Python/MIG/IP。
- 未执行 git add/commit/push/reset/clean/stash。
- hard-readonly：未修改 `AGENT_RULES.md` 或任务 `ACCEPTANCE.md`。
- 是否越界：no。

## 5. 当前顶层、子模块、调用逻辑与数据走向

### 5.1 板级入口

当前板级顶层是 `rtl/hdl/user/Top.v`。它对外只有当前 multiboot 首阶段需要的板级接口：

- `P_G_CLK`：板载 50 MHz 时钟。
- `P_G_RST_N`：低有效复位。
- `P_UART1_RX` / `P_UART1_TX`：UART1 收发。
- `P_led_out`：镜像身份 LED。

Top 中先把外部低有效 reset 转为 50 MHz 域内部高有效 reset：异步断言、同步释放。后续 UART、controller、wrapper、LED 都在同一个 `P_G_CLK` 时钟域内运行。

### 5.2 正常触发数据流

```text
PC/串口工具
  -> P_UART1_RX
  -> uart_rx_byte
  -> uart_boot_trigger command parser
  -> uart_tx_byte sends ACK 0x06
  -> req_valid/req_ready + req_addr
  -> multiboot_ctrl
  -> cmd_valid/cmd_ready + cmd_data/cmd_last
  -> multiboot_icape2_wrapper
  -> ICAPE2
  -> WBSTAR + IPROG
```

核心语义：

- UART 输入必须完整匹配 `BOOT APP\r\n` 或 `BOOT GOLDEN\r\n`。
- `BOOT APP\r\n` 对应 WBSTAR payload `0x00800000`。
- `BOOT GOLDEN\r\n` 对应 WBSTAR payload `0x00000000`。
- 命令合法后，系统先通过 UART TX 发二进制 ACK `0x06`。
- ACK 完整发完之后，`uart_boot_trigger` 才把 `req_valid_o` 拉高，并携带 `req_addr_o`。
- `multiboot_ctrl` 空闲时 `req_ready_o=1`，握手后锁存地址并进入发送状态。

### 5.3 `uart_boot_trigger`

`uart_boot_trigger` 内部包含三层逻辑：

- `uart_rx_byte`：把异步串口 RX 通过两级同步器带入 50 MHz 域，按 8N1 解出 byte，并产生 `data_valid_o` 或 `frame_err_o`。
- command parser：逐字节匹配 `BOOT APP\r\n` / `BOOT GOLDEN\r\n`，错误字节回到起始状态，半条命令超过 `PARAM_CMD_TIMEOUT_CYCLES` 清空状态。
- `uart_tx_byte`：合法命令后发送 ACK byte `0x06`，TX done 后才允许 request 进入 valid-ready 侧。

它还处理一个关键安全点：当 request pending 或 `req_valid_o=1` 但下游还没 ready 时，新收到的 UART 字节不会覆盖已经选好的目标地址。这避免了背压期间 APP/GOLDEN 目标被第二条命令改写。

### 5.4 `multiboot_ctrl`

`multiboot_ctrl` 是抽象配置命令生成器，不直接绑定器件原语。它接收：

```text
req_valid_i + req_ready_o + req_addr_i
```

握手后输出 8 个 32-bit 配置字：

| index | logical cmd | 含义 |
|---:|---:|---|
| 0 | `0xFFFFFFFF` | dummy |
| 1 | `0xAA995566` | sync word |
| 2 | `0x20000000` | noop |
| 3 | `0x30020001` | write WBSTAR header |
| 4 | `req_addr_i` | WBSTAR payload |
| 5 | `0x30008001` | write CMD header |
| 6 | `0x0000000F` | IPROG command |
| 7 | `0x20000000` | trailing noop |

输出侧是标准 valid-ready：`cmd_valid_o` 表示当前字有效，`cmd_ready_i` 表示 wrapper 可接收，`cmd_last_o` 在最后一个 word 标记结束。

### 5.5 `multiboot_icape2_wrapper`

`multiboot_icape2_wrapper` 把抽象 32-bit command stream 转成 `ICAPE2` 写入：

- `cmd_ready_o = icap_enable_i && !reset`。
- 发生 `cmd_valid_i && cmd_ready_o` 时，`icap_csib_o=0`，`icap_rdwrb_o=0`。
- `cmd_data_i` 写入 ICAPE2 前，每个 byte 内做 bit reverse。
- ICAPE2 原语参数为 `ICAP_WIDTH="X32"`。

注意：ICAPE2 没有 ready 输出，wrapper 的 `cmd_ready_o` 只是工程内部对“允许写入”的控制。当前 Top 里 `icap_enable_i` 固定为 `1'b1`。

### 5.6 LED 镜像身份

Top 中 LED 只用于区分当前镜像身份，不参与 multiboot 控制：

- `PARAM_IMAGE_IS_APPLICATION=0`：Golden，LED 1 Hz。
- `PARAM_IMAGE_IS_APPLICATION=1`：Application，LED 4 Hz。

Application bitstream 后续构建时必须显式设置该 generic，否则两份镜像都会表现为 Golden LED 频率。

## 6. 仿真层对什么仿真，目的是什么

当前 S7/S8 关注的是 Top/UART 集成级功能仿真，不是综合、实现或上板。

仿真对象由 `tcl/sim/xsim_top_uart_multiboot.tcl` 编译并 elaborate：

- `Top.v`
- `uart_boot_trigger.v`
- `multiboot_ctrl.v`
- `multiboot_icape2_wrapper.v`
- `tb_top_uart_multiboot.v`
- Vivado `glbl.v`
- UNISIM `ICAPE2` / `SIM_CONFIGE2`

仿真目的有四个：

- 证明 UART 文本命令可以穿过真实 RX/parser/TX ACK/request 逻辑。
- 证明 Top 级 request 能驱动 controller 生成正确 8-word ICAP 写序列。
- 证明 wrapper 对 ICAP 控制脚和 byte bit-reversal 的处理符合预期。
- 证明 UNISIM 模型最终能观察到 APP/GOLDEN 对应的 `WBSTAR` 和 `IPROG`。

证据边界也要说清楚：XSim PASS 只说明仿真模型中这条控制链闭环通过，不证明 XDC property、生成为 bitstream、Flash 内容、真实 UART 电气连接、真实 FPGA 重配置或 fallback 行为。

## 7. 激励数据送入哪里，testbench 如何仿真子模块

### 7.1 仿真参数为什么缩短

`tb_top_uart_multiboot.v` 为了加快仿真，把 DUT 参数设置为：

```text
PARAM_CLK_FREQ_HZ = 1000
PARAM_UART_BAUD   = 100
```

这样 UART 每 bit 是 10 个仿真 clock。它验证的是“参数化 UART 逻辑和协议状态机”，不是用真实 50 MHz / 115200 baud 做长时间仿真。真实默认参数仍保留在 RTL 中。

### 7.2 standalone UART trigger 激励

TB 单独实例化了一个 `uart_boot_trigger`。激励通过 `trigger_rx_r` 送入，相当于直接给该子模块的 UART RX pin 喂 8N1 串行波形。

它覆盖：

- `BOOT BAD\r\n`：应不 ACK、不产生 request。
- `BOOT A` 后等待超过 timeout，再送 `PP\r\n`：应不形成 APP request。
- `BOOT APP\r\n`：应收到 ACK `0x06`，随后在 `req_ready_i=0` 时保持 `req_valid_o=1` 和 `req_addr_o=0x00800000`。
- 背压期间再送 `BOOT GOLDEN\r\n`：不应覆盖 pending APP 地址。
- ready 释放后 APP handshake；随后再验证 `BOOT GOLDEN\r\n` 产生 `0x00000000`。

这里的目的不是验证 ICAP，而是隔离验证 UART parser、ACK 顺序、timeout 和 valid-ready 保持。

### 7.3 Top APP 激励

TB 实例化一个 `Top dut`，通过 `top_uart_rx_r` 给 `P_UART1_RX` 喂完整 `BOOT APP\r\n` 的 8N1 串行波形。

然后 TB：

- 从 `P_UART1_TX` 解码 ACK，要求收到 `0x06`。
- 等待 `dut.ctrl_done_w`。
- monitor `dut.cmd_valid_w && dut.cmd_ready_w` 的 8 次转移。
- 检查每个 `dut.cmd_data_w` 是否等于预期配置字。
- 检查 `dut.icap_data_i_w` 是否等于 byte bit-reversal 后的数据。
- 检查 UNISIM 内部 `wbstar_reg[0] == 0x00800000`。
- 检查 `iprog_b[0]` 出现下降沿，说明 UNISIM 解码到 IPROG。

### 7.4 Top GOLDEN 激励

TB 还实例化了独立的 `Top dut_golden`，通过 `golden_uart_rx_r` 喂 `BOOT GOLDEN\r\n`。

这里使用独立 Top 实例是有意的：真实 IPROG 触发后器件会重配置，不应该在同一个已触发 IPROG 的配置上下文里继续期待第二条命令还能正常运行。独立实例让 APP 和 GOLDEN 两条路径分别被验证，避免 testbench 假设违背真实重配置语义。

GOLDEN 检查与 APP 相同，只是目标地址要求为 `0x00000000`。

### 7.5 Monitor 如何判断失败

TB 的失败条件主要有：

- 出现 `CHECK_FAIL`。
- ACK 不是 `0x06`。
- 非法/超时命令产生 ACK 或 request。
- backpressure 下 request 地址被覆盖。
- ICAP command 数量不是 8。
- 任一 command word、`cmd_last`、ICAPE2 控制脚、bit-reversal 数据不匹配。
- UNISIM `WBSTAR` 或 `IPROG` 未观察到。

所有检查最终汇总到 `fail_count`。`fail_count==0` 时打印 `RESULT=PASS`，否则打印 `RESULT=FAIL`。

## 8. 观察到什么理想数据，才可以推进下一阶段编译上板

对当前阶段来说，理想数据分三层。

### 8.1 编译/elaboration 层

理想现象：

- `xvlog` 能分析 `Top`、UART、controller、wrapper、TB。
- `xelab` 能 elaborate `Top`、`uart_boot_trigger`、`multiboot_ctrl`、`multiboot_icape2_wrapper`、`unisims_ver.ICAPE2`、`unisims_ver.SIM_CONFIGE2`。
- 生成 snapshot 和 WDB。

当前已有证据：`20260719_235747_xsim-top-uart-multiboot` 为 SUCCESS。

### 8.2 UART/request 层

理想现象：

- 非法命令和 timeout 命令不产生 request。
- 合法命令返回 ACK `0x06`。
- ACK 完整发送后才发 request。
- request 地址正确：APP=`0x00800000`，GOLDEN=`0x00000000`。
- 下游 not-ready 时 `req_valid/req_addr` 保持，不被后续 UART 输入覆盖。

当前已有证据：最终 xsim log 没有 `CHECK_FAIL`，并打印相关 test case 后最终 `RESULT=PASS`。

### 8.3 ICAP/UNISIM 层

理想 APP 数据：

```text
TOP_ICAP_WRITE index=4 logical=0x00800000 physical=0x00010000
CHECK_PASS: Top UNISIM WBSTAR=0x00800000
CHECK_PASS: Top UNISIM IPROG pulse observed
```

理想 GOLDEN 数据：

```text
GOLDEN_TOP_ICAP_WRITE index=4 logical=0x00000000 physical=0x00000000
CHECK_PASS: Golden Top UNISIM WBSTAR=0x00000000
CHECK_PASS: Golden Top UNISIM IPROG pulse observed
```

理想最终结果：

```text
RESULT=PASS
```

当前 latest run `20260719_235747_xsim-top-uart-multiboot` 已满足以上 XSim 层理想数据。因此可以推进到下一阶段“编译/构建属性审计”，也就是检查 Vivado 工程、XDC property、synth/impl 前置条件。但还不能直接等价为“可上板成功”：上板前至少还需要独立授权并完成 build/property、bitstream、MCS/Flash 和 Hardware Manager 验证。

## 9. 推进下一阶段的建议边界

建议下一阶段不是直接上板，而是 S9 Vivado build/property 审计：

- 确认 `xc7a35tfgg484-2` part 生效，而不是脚本默认 fallback part。
- 确认 `PIN.xdc` 的 clock、UART pins、SPIx4、`CONFIGRATE=12`、fallback、timer、no-compress 被 Vivado 2018.3 接受。
- 先跑 synth/elab/property 查询，不生成 bitstream 或写板，除非新 prompt 明确授权。
- Application 构建必须显式设置 `PARAM_IMAGE_IS_APPLICATION=1`。

## 10. 修改摘要

- 新增本轮说明报告。
- 更新 `TASK_STATE.md`、`HANDOFF_CURRENT.md`、`TASK_INDEX.md`，把 008 梳理报告作为最新接力入口，并记录当前 latest run 漂移到 `20260719_235747_xsim-top-uart-multiboot`。
- 未修改工程 RTL/TB/Tcl/Shell/XDC。

## 11. 实际改动文件

- `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260720_003126_top_uart_logic_and_tb_arrangement_report.md`（新增）
- `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/TASK_STATE.md`
- `ai_workflow/HANDOFF_CURRENT.md`
- `ai_workflow/TASK_INDEX.md`

用户已有输入：

- `prompts/codex/008_multiboot_new_top_uart_integrated_selftest_testbench_arrange.md`：开工前未跟踪文件，本轮未修改。

## 12. 额外自主修改说明

本轮没有修改工程代码。状态文件更新是因为 008 prompt 允许更新 `ai_workflow`，且 handoff/TASK_STATE/TASK_INDEX 需要指向最新报告和当前 latest run。

- 默认行为：不影响。
- legacy path：不影响。
- 风险：报告是解释性材料，不能替代新的 EDA/build/board 证据。
- 建议人工重点 review：第 5-8 节的模块关系、TB 激励解释和推进下一阶段判据是否符合硬件真实意图。

## 13. 验证情况

- 本轮只读复核源码、TB、Tcl、前置 report、git 状态和已有 XSim 日志。
- 未重跑 Vivado。
- 只读确认 `20260719_235747_xsim-top-uart-multiboot`：`result=SUCCESS`、`RESULT=PASS`、WDB 存在且 660151 bytes。

## 14. 未执行事项

- 未运行 Vivado/XSim。
- 未运行综合、实现、DRC、timing。
- 未生成 bitstream、MCS/BIN。
- 未连接 Hardware Manager、未写 Flash、未上板。
- 未执行 git 写操作。

## 15. 风险与注意事项

- 当前 Top TB 使用缩短参数 `1000 Hz / 100 baud` 加速仿真，不是默认 `50 MHz / 115200 baud` 的长仿真。
- XSim 中观察到 UNISIM IPROG pulse 不等于真实器件完成重配置。
- 当前脚本 summary 仍可能显示默认 `part_name=xc7vx690tffg1927-2`，下一阶段必须审计 part/property 是否按 `xc7a35tfgg484-2` 生效。
- XDC 和 bitstream property 尚未由 build gate 证明。

## 16. 下一轮建议

人工审查本报告，确认当前逻辑理解无误后，另起 S9 Vivado build/property 审计 gate。该 gate 应限制为工程构建属性核验，不直接上板、不写 Flash，除非 prompt 明确扩大授权。

## 17. 待授权事项

- S9：Vivado build/property 审计。
- 后续：synth/impl/timing/DRC、bitstream/MCS/BIN、Flash 写入、Hardware Manager 上板验证。

## 18. FPGA 调试 yes/no 状态

- 是否修改 RTL：no。
- 是否修改 XDC：no。
- 是否修改 Tcl：no。
- 是否修改 Python：no。
- 是否运行 Vivado：no。
- 是否生成 bitstream：no。
- 是否上板：no。
- 是否发送真实 UDP 包：no。
- 是否修改 MIG/IP：no。

## 19. 最终 Git 状态

最终 `git status --short --untracked-files=all`：

```text
 M ai_workflow/HANDOFF_CURRENT.md
 M ai_workflow/TASK_INDEX.md
 M ai_workflow/tasks/20260717_multiboot_ctrl_fsm/TASK_STATE.md
?? ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260720_003126_top_uart_logic_and_tb_arrangement_report.md
?? prompts/codex/008_multiboot_new_top_uart_integrated_selftest_testbench_arrange.md
```

## 20. 最终 Git Diff Stat

最终 `git diff --stat`：

```text
 ai_workflow/HANDOFF_CURRENT.md                     | 28 ++++++++++------------
 ai_workflow/TASK_INDEX.md                          |  3 ++-
 .../20260717_multiboot_ctrl_fsm/TASK_STATE.md      | 13 ++++++----
 3 files changed, 23 insertions(+), 21 deletions(-)
```

普通 `git diff --stat` 不包含未跟踪的新 report 和 008 prompt；二者已由最终 `git status` 标注。`git diff --check` 最终 PASS。
