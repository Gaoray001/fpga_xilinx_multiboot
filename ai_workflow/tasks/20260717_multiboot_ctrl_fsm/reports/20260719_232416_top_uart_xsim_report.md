# 报告：S7 Top/UART Vivado XSim 自检

- AI 模型类型：Codex / GPT-5 coding agent
- 时间戳：20260719_232416
- 本轮任务：读取并执行 `prompts/codex/007_push_vivado_xsim_exec.md`
- 本轮 gate：S7 Linux Vivado 编译/XSim
- 最终结论：Top/UART 自检 TB、Tcl 和 shell 入口已新增；最终 Vivado 2018.3 `xvlog/xelab/xsim` run `20260719_232340_xsim-top-uart-multiboot` 为 SUCCESS，日志含 `RESULT=PASS`。

## 1. git baseline

- branch：`dev`
- baseline commit：`3ebbc88 增加uart触发源+multiboot逻辑-未上板卡验证`
- recent log：
  - `3ebbc88 增加uart触发源+multiboot逻辑-未上板卡验证`
  - `9dc8ee4 硬件板卡边界确定+Top板级实现方案规划`
  - `27bbdef 增加multiboot逻辑实现理解`
  - `ff9adfc 增加multiboot原语ICAPE2`
  - `076720e 增加最小multiboot逻辑实现`
- 开工 `git status --short`：

```text
?? prompts/codex/007_push_vivado_xsim_exec.md
```

- 开工 `git diff --stat`：空。

说明：前置 S6 report 记录的 S6 工程脏改动已在开工前进入 commit `3ebbc88`；本轮以当前仓库事实为准。未跟踪 007 prompt 为用户输入，本轮未修改。

## 2. 输入事实摘要

- 当前分支：`dev`。
- 活跃任务目录：`ai_workflow/tasks/20260717_multiboot_ctrl_fsm`。
- 前置报告：`reports/20260719_205547_board_top_uart_integration_static_report.md`。
- 平台事实：Xilinx 7 Series / Zynq-7000 PL 侧 ICAP，使用 `ICAPE2`；Linux 用于 RTL 开发和 XSim 仿真。
- 板卡事实：`xc7a35tfgg484-2`、`N25Q128A13ESE40G` 16 MiB、50 MHz W19、低有效 reset N15、UART1 TX N17/RX P17、Master SPI x4 `M[2:0]=001`。

## 3. latest report 发现

- 开工时当前任务 `reports/` 实际最新文件：`20260719_205547_board_top_uart_integration_static_report.md`。
- 与 007 prompt 指定前置报告一致。
- `TASK_INDEX.md` 开工时仍指向“审查 S6 后授权 S7”，而 007 prompt 已明确授权 S7；按优先级采用本轮 prompt。

## 4. 边界自检

- WRITE_ALLOW：允许更新 `ai_workflow` 状态文件；允许新增本任务 reports；允许修改 UART/Top TB/Tcl/Shell。
- RUN_POLICY：R2，可运行且可修改；允许非删除 shell；允许运行 Vivado XSim；不允许 git 写。
- HARD_BOUNDARY：允许新增报告、更新 `ai_workflow` 状态文件。
- OVERRIDE_BOUNDARY：未提供。
- hard-readonly：未修改 `ai_workflow/AGENT_RULES.md` 或任务 `ACCEPTANCE.md`。
- 实际工程修改：新增 `sim/tb/tb_top_uart_multiboot.v`，新增 `tcl/sim/xsim_top_uart_multiboot.tcl`，修改 `scripts/vivado2018_common.sh`。
- 实际状态/报告修改：本报告、`TASK_STATE.md`、`HANDOFF_CURRENT.md`、`TASK_INDEX.md`。
- 实际运行命令：只读 `sed/rg/ls/wc/date/git status/git diff/git log/readlink`；`git diff --check`；`./scripts/vivado2018_common.sh xsim-top-uart-multiboot` 两次。
- 是否触碰禁止项：no。
- 是否执行 git 写：no。
- 是否越界：no。

## 5. 实现摘要

新增 `tb_top_uart_multiboot.v`：

- 使用缩短仿真参数 `PARAM_CLK_FREQ_HZ=1000`、`PARAM_UART_BAUD=100`，保持 UART bit divisor=10 cycles，加速 XSim；真实 RTL 设计默认参数未改。
- 独立实例化 `uart_boot_trigger`，覆盖非法命令拒绝、partial-command timeout、ACK `0x06`、valid-ready backpressure hold、request 地址不覆盖、`BOOT APP`/`BOOT GOLDEN` 地址。
- 实例化两个独立 `Top`，分别验证 APP 和 GOLDEN；避免把“IPROG 后继续在同一配置里运行第二条命令”当成真实器件行为。
- Top 自检检查 8-word ICAP 命令序列、`cmd_last`、ICAPE2 控制脚、每 byte bit-reversal 后物理数据、UNISIM `WBSTAR` 和 `IPROG` pulse。

新增 `xsim_top_uart_multiboot.tcl`：

- 编译 `Top.v`、`uart_boot_trigger.v`、`multiboot_ctrl.v`、`multiboot_icape2_wrapper.v`、`tb_top_uart_multiboot.v`、`glbl.v`。
- 使用 `-L unisims_ver` elaboration，并要求 xsim 日志出现 `RESULT=PASS` 且不出现 `RESULT=FAIL`。

修改 `scripts/vivado2018_common.sh`：

- 新增命令 `xsim-top-uart-multiboot`。
- 对该命令的成功 run 更新 `_artifacts/latest`，判据为 PASS log + WDB 存在。

## 6. Vivado / XSim 运行记录

### 6.1 首次 run（失败，TB 假设修正）

- run：`20260719_232158_xsim-top-uart-multiboot`
- result：FAILED
- 原因：TB 在同一个 `ICAPE2` UNISIM 实例里先 APP IPROG 后继续发 GOLDEN，并期望第二次 WBSTAR/IPROG；真实 IPROG 语义下设计会重配置，不能把同一配置继续运行第二条命令作为验收假设。
- 处置：未改设计 RTL；调整 TB 为 APP 和 GOLDEN 使用两个独立 Top/ICAPE2 实例。

### 6.2 最终 run（通过）

- command：`./scripts/vivado2018_common.sh xsim-top-uart-multiboot`
- run：`20260719_232340_xsim-top-uart-multiboot`
- result：SUCCESS
- xsim log：`_runs/common_vivado/20260719_232340_xsim-top-uart-multiboot/logs/top_uart_multiboot_xsim.log`
- xelab log：`_runs/common_vivado/20260719_232340_xsim-top-uart-multiboot/logs/top_uart_multiboot_xelab.log`
- xvlog log：`_runs/common_vivado/20260719_232340_xsim-top-uart-multiboot/logs/top_uart_multiboot_xvlog.log`
- WDB：`_artifacts/common_vivado/20260719_232340_xsim-top-uart-multiboot/top_uart_multiboot.wdb`，660151 bytes。
- `_runs/latest`：`common_vivado/20260719_232340_xsim-top-uart-multiboot`
- `_artifacts/latest`：`common_vivado/20260719_232340_xsim-top-uart-multiboot`

最终日志关键证据：

```text
Built simulation snapshot top_uart_multiboot_snapshot
CHECK_PASS: Top UNISIM ICAPE2 initialization observed
CHECK_PASS: Golden Top UNISIM ICAPE2 initialization observed
CHECK_PASS: Top UNISIM WBSTAR=0x00800000
CHECK_PASS: Top UNISIM IPROG pulse observed
CHECK_PASS: Golden Top UNISIM WBSTAR=0x00000000
CHECK_PASS: Golden Top UNISIM IPROG pulse observed
RESULT=PASS
```

xelab 关键证据：

```text
Compiling module xil_defaultlib.uart_boot_trigger(...)
Compiling module xil_defaultlib.multiboot_ctrl_default
Compiling module unisims_ver.SIM_CONFIGE2(...)
Compiling module unisims_ver.ICAPE2
Compiling module xil_defaultlib.multiboot_icape2_wrapper
Compiling module xil_defaultlib.Top(...)
Compiling module xil_defaultlib.tb_top_uart_multiboot
```

## 7. 验证覆盖

- UART standalone：非法 `BOOT BAD\r\n` 不 ACK、不 request。
- UART standalone：`BOOT A` 后超时，再补 `PP\r\n` 不形成 APP request。
- UART standalone：合法 APP 先 ACK，再在 `req_ready_i=0` 下保持 `req_valid_o/req_addr_o`。
- UART standalone：backpressure 期间输入 `BOOT GOLDEN\r\n` 不覆盖 pending APP 地址。
- UART standalone：释放 ready 后 APP handshake，再验证 GOLDEN handshake。
- Top APP：`BOOT APP\r\n` 触发 WBSTAR `0x00800000` 和 IPROG。
- Top GOLDEN：独立 Top 实例中 `BOOT GOLDEN\r\n` 触发 WBSTAR `0x00000000` 和 IPROG。
- ICAP：每轮 8 个逻辑配置字和 bit-reversal 后物理数据均匹配预期。

## 8. 修改摘要

- 新增 Top/UART 集成自检 testbench。
- 新增 Top/UART XSim Tcl。
- 扩展 Vivado wrapper shell 的命令枚举和 artifact latest 成功判据。
- 更新任务状态、handoff 和任务索引。
- 未修改设计 RTL、XDC、Python、MIG/IP。

## 9. 实际改动文件

- `sim/tb/tb_top_uart_multiboot.v`（新增）
- `tcl/sim/xsim_top_uart_multiboot.tcl`（新增）
- `scripts/vivado2018_common.sh`
- `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260719_232416_top_uart_xsim_report.md`（新增）
- `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/TASK_STATE.md`
- `ai_workflow/HANDOFF_CURRENT.md`
- `ai_workflow/TASK_INDEX.md`

用户已有输入：

- `prompts/codex/007_push_vivado_xsim_exec.md`：开工前未跟踪文件，本轮未修改。

## 10. 扩大修改与额外自主修改说明

本轮工程文件数为 3 个，符合默认文件数上限；但新增 TB 约 881 行、Tcl 约 111 行，超过默认 80 行轻量修改阈值，标记为“扩大修改”。

- 必要性：UART 串行激励、ACK 解码、timeout/backpressure、自检 monitor、Top APP/GOLDEN 两套 UNISIM 验证无法在 80 行内可靠覆盖。
- 授权依据：007 prompt 明确允许修改 UART/Top TB/Tcl/Shell，并允许运行 Vivado XSim。
- 默认行为：不改变设计 RTL 默认行为；只新增验证入口。
- legacy path：既有 `xsim-multiboot-ctrl` 入口未改语义，只扩展 shell 命令枚举。
- 风险：TB 使用缩短仿真参数加速 UART，不证明 50 MHz/115200 实时时序；该默认参数仍需后续 board/build 证据。
- 人工重点 review：TB 串口采样点、timeout 缩短参数、独立 Top GOLDEN 实例、artifact latest 判据。

## 11. 未执行事项

- 未运行综合、实现、DRC、timing。
- 未生成 bitstream、MCS/BIN。
- 未连接 Hardware Manager、未写 Flash、未上板。
- 未发送真实 UART/UDP。
- 未执行 git add/commit/push/reset/clean/stash。

## 12. 风险与注意事项

- S7 XSim PASS 不等于真实 FPGA 重配置成功；UNISIM IPROG pulse 只是仿真模型解码证据。
- Top TB 为加速仿真覆盖使用 `PARAM_CLK_FREQ_HZ=1000`、`PARAM_UART_BAUD=100`，设计默认 `50_000_000/115_200` 尚未在默认参数下跑长仿真。
- XDC 属性 `CONFIGRATE/TIMER_CFG/fallback/no-compress` 尚未经过 synth/impl/bitstream property 审计。
- Application bitstream 仍必须设置 `PARAM_IMAGE_IS_APPLICATION=1`。

## 13. 下一轮建议

人工审查本报告和 S7 TB/Tcl/Shell diff；确认后另起 S8 Vivado build/property 审计 gate，重点验证 XDC property 是否被 Vivado 2018.3 接受，并决定是否进入 bitstream/MCS gate。

## 14. 待授权事项

- S8：Vivado project/build/property 审计。
- 后续：synth/impl/timing/DRC、bitstream/MCS/BIN、Flash 写入、Hardware Manager 上板验证均需单独授权。

## 15. FPGA 调试 yes/no 状态

- 是否修改 RTL：no，未修改设计 RTL；新增 testbench。
- 是否修改 XDC：no。
- 是否修改 Tcl：yes，新增 XSim Tcl，007 prompt 授权；风险是新入口需人工 review。
- 是否修改 Shell：yes，新增 `xsim-top-uart-multiboot` 命令，007 prompt 授权。
- 是否修改 Python：no。
- 是否运行 Vivado：yes，运行 Vivado 2018.3 `xvlog/xelab/xsim`，007 prompt 授权；证据为最终 run 日志。
- 是否生成 bitstream：no。
- 是否上板：no。
- 是否发送真实 UDP 包：no。
- 是否修改 MIG/IP：no。

## 16. 最终 Git 状态

最终 `git status --short --untracked-files=all`：

```text
 M ai_workflow/HANDOFF_CURRENT.md
 M ai_workflow/TASK_INDEX.md
 M ai_workflow/tasks/20260717_multiboot_ctrl_fsm/TASK_STATE.md
 M scripts/vivado2018_common.sh
?? ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260719_232416_top_uart_xsim_report.md
?? prompts/codex/007_push_vivado_xsim_exec.md
?? sim/tb/tb_top_uart_multiboot.v
?? tcl/sim/xsim_top_uart_multiboot.tcl
```

## 17. 最终 Git Diff Stat

最终 `git diff --stat`：

```text
 ai_workflow/HANDOFF_CURRENT.md                     | 23 +++++++++++-----------
 ai_workflow/TASK_INDEX.md                          |  3 ++-
 .../20260717_multiboot_ctrl_fsm/TASK_STATE.md      | 18 +++++++++++------
 scripts/vivado2018_common.sh                       | 15 +++++++++++---
 4 files changed, 37 insertions(+), 22 deletions(-)
```

普通 `git diff --stat` 不包含新增未跟踪文件；新增 TB、Tcl、report 和 007 prompt 已由最终 `git status` 单独列出。`git diff --check` 最终 PASS。
