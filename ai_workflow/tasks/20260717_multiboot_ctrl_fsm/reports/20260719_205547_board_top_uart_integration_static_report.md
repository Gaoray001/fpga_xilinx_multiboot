# 报告：板级 Top + UART Multiboot 触发集成与静态自检

- AI 模型类型：Codex / GPT-5 coding agent
- 时间戳：20260719_205547
- 本轮任务：读取并执行 `prompts/codex/006_board_level_top_uart_trigger_integration_def_impl.md`
- 本轮 gate：S6 板级 Top + UART 触发定义/实现
- 最终结论：Top/UART/LED/XDC 集成实现完成，非 Vivado 结构化静态自检 PASS；未执行 RTL 编译、XSim、综合、实现或上板。

## 1. git baseline

- branch：`dev`
- baseline commit：`9dc8ee4 硬件板卡边界确定+Top板级实现方案规划`
- recent log：
  - `9dc8ee4 硬件板卡边界确定+Top板级实现方案规划`
  - `27bbdef 增加multiboot逻辑实现理解`
  - `ff9adfc 增加multiboot原语ICAPE2`
  - `076720e 增加最小multiboot逻辑实现`
  - `e9a8047 Xsim冒烟测试-可观察vivado仿真波形`
- 开工 `git status --short`：

```text
 M prompts/codex/006_board_level_top_uart_trigger_integration_def_impl.md
```

- 开工 `git diff --stat`：

```text
 prompts/codex/006_board_level_top_uart_trigger_integration_def_impl.md | 1 +
 1 file changed, 1 insertion(+)
```

- 该 1 行是用户新增硬件事实 `MASTER SPI x4 M[2:0] = 001`；本轮保留，未修改、未回滚。

## 2. 输入事实摘要

- FPGA：`xc7a35tfgg484-2`。
- Flash：`N25Q128A13ESE40G`，16 MiB。
- UART1：TX=N17、RX=P17、LVCMOS33。
- 板载时钟：W19，50 MHz。
- 板载复位：N15，低有效。
- 配置模式：Master SPI x4，`M[2:0]=001`。
- S5 地址：Golden=`0x00000000`，Application=`0x00800000`。
- 本轮禁止运行 Vivado、禁止 Git 写操作。

## 3. latest report 发现

- 开工时当前任务 `reports/` 实际最新文件：
  `20260719_194352_multiboot_flash_layout_solution_report.md`。
- 与 006 prompt 指定的前置报告一致，无漂移。
- `TASK_INDEX.md` 的下一步为 S6 Top + UART 集成，与本轮目标一致。

## 4. 边界自检

- WRITE_ALLOW：允许修改 Top/UART/LED RTL、XDC、相应 TB/Tcl；允许更新 `ai_workflow` 状态并新增本报告。
- RUN_POLICY：R2；允许非删除 shell；明确禁止 Vivado，禁止 Git 写。
- HARD_BOUNDARY：工程代码仅修改 prompt 授权类别，状态写入仅限 `ai_workflow`。
- OVERRIDE_BOUNDARY：未提供。
- hard-readonly：未修改 `AGENT_RULES.md` 或任务 `ACCEPTANCE.md`。
- 实际工程修改：`Top.v`、新增 `uart_boot_trigger.v`、`PIN.xdc`，共 3 个授权文件。
- 实际状态/报告修改：本报告、`TASK_STATE.md`、`HANDOFF_CURRENT.md`、`TASK_INDEX.md`。
- 实际命令：只读 Git、`sed/rg/find/wc/awk/date/command/compgen`，以及只读 Python 结构审计。
- 是否运行 Vivado/EDA：no。
- 是否执行 Git 写：no。
- 是否触碰禁止项：no。
- 是否修改 hard-readonly：no。
- 是否越界：no。

## 5. 实现架构

```text
P_UART1_RX
  -> two-flop CDC
  -> uart_rx_byte (115200 8N1)
  -> exact command parser + 500 ms inter-byte timeout
  -> uart_tx_byte sends ACK 0x06
  -> req_valid/req_ready + WBSTAR payload
  -> multiboot_ctrl
  -> multiboot_icape2_wrapper
  -> ICAPE2

P_G_CLK 50 MHz
  -> reset synchronizer
  -> UART / controller / wrapper / LED single clock domain
```

既有 `multiboot_ctrl` 和 `multiboot_icape2_wrapper` 未修改。两者端口名保留 legacy `100M` 后缀，但本轮统一接入板载 50 MHz；逻辑本身不依赖 100 MHz 固定计时。

## 6. Top 定义

`rtl/hdl/user/Top.v` 现包含完整板级顶层：

```text
P_G_CLK     input   W19 / 50 MHz
P_G_RST_N   input   N15 / active-low
P_UART1_TX  output  N17 / LVCMOS33
P_UART1_RX  input   P17 / LVCMOS33
P_led_out   output  M21 / LVCMOS33
```

Top 参数：

| 参数 | 默认值 | 含义 |
|---|---:|---|
| `PARAM_IMAGE_IS_APPLICATION` | 0 | 0=Golden，非 0=Application |
| `PARAM_CLK_FREQ_HZ` | 50,000,000 | UART/LED 计时基准 |
| `PARAM_UART_BAUD` | 115,200 | UART 8N1 波特率 |
| `PARAM_GOLDEN_ADDR` | `0x00000000` | Golden WBSTAR payload |
| `PARAM_APPLICATION_ADDR` | `0x00800000` | Application WBSTAR payload |

Golden 默认构建 LED 为 1 Hz；Application 参数构建 LED 为 4 Hz。后续 Application build 应在工程 fileset 上设置：

```tcl
set_property generic {PARAM_IMAGE_IS_APPLICATION=1} [current_fileset]
```

本轮只定义该机制，没有运行或修改构建 Tcl。

## 7. Reset / CDC

- 外部 `P_G_RST_N` 在 Top 中异步断言、两拍同步释放，内部统一转换为 50 MHz 域高有效 reset。
- 异步 UART RX 在 `uart_rx_byte` 内经过两级同步寄存器。
- reset 同步器和 UART RX 同步器均标注 `ASYNC_REG="TRUE"`。
- UART 解析、request handshake、controller、wrapper 和 LED 均位于同一个 50 MHz 域，没有新增多 bit CDC。

## 8. UART 协议与安全触发

UART 固定为 115200, 8N1。50 MHz 下取整后的每 bit 周期为 434 clocks：

```text
actual baud = 50,000,000 / 434 = 115,207.373
error       = +0.0064%
```

只接受两条大小写敏感、完整带 CRLF 的命令：

```text
BOOT APP\r\n     -> WBSTAR 0x00800000
BOOT GOLDEN\r\n  -> WBSTAR 0x00000000
```

安全行为：

- 错误字节回到命令起始状态，不产生 request。
- UART stop bit 错误清空当前解析状态。
- 半条命令超过 25,000,000 clocks（500 ms）未继续，清空解析状态。
- 合法命令完成后先发送 ACK byte `0x06`。
- 只有 UART TX 完整发送 ACK 后才置 `req_valid_o=1`。
- `req_valid_o` 与 `req_addr_o` 在 `req_ready_i=0` 时保持；仅在 `valid && ready` 后清除。
- request pending 或 valid 期间忽略新 UART 字节，防止覆盖目标地址。

## 9. LED 镜像身份

- Golden：half-period=25,000,000 clocks，完整闪烁周期 1.000 Hz。
- Application：half-period=6,250,000 clocks，完整闪烁周期 4.000 Hz。
- 由同一个 Top 参数选择，便于两份 bitstream 使用相同逻辑结构，仅改变可视身份。

## 10. XDC 变更

`constraints/PIN.xdc` 新增/更新：

- `create_clock -period 20.000`，定义 W19 50 MHz。
- UART1 TX=N17、RX=P17、LVCMOS33。
- 保持 Master SPI x4、3.3 V 配置。
- `CONFIGRATE` 从原 50 调整为 S5 首板建议的保守 12 MHz。
- 新增 `CONFIGFALLBACK ENABLE`。
- 新增 `TIMER_CFG 0x00050000`。
- 明确 `COMPRESS FALSE`，便于首次容量/地址审计。
- 未设置任何 `NEXT_CONFIG_ADDR` / `NEXT_CONFIG_REBOOT`，运行时仍由 UART + ICAPE2 触发。

`CONFIGRATE/TIMER_CFG/fallback` 目前只是 XDC 静态定义，必须经后续 Vivado property、bitstream 和上板证据验证。

## 11. 静态自检

### 11.1 工具可用性

- PATH 与 `/usr/local`、`/opt` 范围未发现 Icarus Verilog、Verilator、Yosys、Slang、Surelog 或 Verible。
- 本轮又明确禁止 Vivado，因此未调用 `xvlog/xelab/xsim`。
- 采用只读结构化审计，不冒充 Verilog 编译器。

### 11.2 PASS 项

- `git diff --check`：PASS。
- 修改 RTL 的 `module/endmodule`、`begin/end`、`case/endcase` 数量平衡：PASS。
- `()`、`[]`、`{}` 分隔符平衡：PASS。
- 修改 RTL 无 tab、无行尾空白：PASS。
- Top 五个板级端口与三段例化链存在：PASS。
- Reset async-assert/sync-release 与 RX 双触发器 CDC 标记：PASS。
- `BOOT APP` / `BOOT GOLDEN` 状态转移关键链和地址映射：PASS。
- ACK launch、ACK done 后 request、valid-ready 保持：PASS。
- 500 ms partial-command timeout：PASS。
- UART divisor=434、baud error=+0.0064%：PASS。
- Golden 1 Hz / Application 4 Hz 计数：PASS。
- XDC UART pins、20 ns clock、SPIx4/fallback/timer/compress：PASS。
- XDC 不含 `NEXT_CONFIG`：PASS。

### 11.3 自检过程异常

最初两条 Python 审计命令因命令行 f-string/正则转义错误退出，未作为证据；修正为 token-based 结构审计后重跑并全部 PASS。该异常没有修改工程文件，也不是 RTL 失败。

### 11.4 证据边界

本轮静态 PASS 不证明：

- Verilog 能通过 `xvlog`/elaboration。
- UART 波形或命令解析功能仿真通过。
- XDC property 被 Vivado 2018.3 接受。
- 综合/实现时序收敛。
- bitstream/MCS/Flash/真实 ICAPE2 重配置通过。

## 12. 修改摘要

- 将空 `Top.v` 实现为板级单时钟域顶层。
- 新增 UART RX/TX、命令 parser、ACK 与 valid-ready boot request adapter。
- 补齐 50 MHz、UART pins 和首板配置属性 XDC。
- 未修改已通过 XSim 的 controller/wrapper/TB/Tcl。
- 未新增本轮 TB/Tcl：prompt 验收仅要求静态自检，且禁止 Vivado；动态验证留给下一授权 gate。

## 13. 实际改动文件

工程文件：

- `rtl/hdl/user/Top.v`
- `rtl/hdl/user/multiboot/uart_boot_trigger.v`（新增，含 `uart_rx_byte` / `uart_tx_byte` 私有子模块）
- `constraints/PIN.xdc`

工作流文件：

- `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260719_205547_board_top_uart_integration_static_report.md`
- `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/TASK_STATE.md`
- `ai_workflow/HANDOFF_CURRENT.md`
- `ai_workflow/TASK_INDEX.md`

用户已有修改：

- `prompts/codex/006_board_level_top_uart_trigger_integration_def_impl.md`：开工前已有 1 行脏改动，本轮未修改。

## 14. 扩大修改与额外自主修改说明

本轮 3 个工程文件符合默认文件数上限，但新增 RTL 约 645 行，超过默认 80 行轻量修改阈值，标记为“扩大修改”。

- 必要性：完整 UART RX、TX ACK、精确命令 parser、超时、CDC、Top 例化和 LED 身份无法在 80 行内安全完成。
- 授权依据：006 prompt 明确允许修改 Top/UART/LED RTL 和 XDC，目标明确要求完成实现。
- 默认行为：`Top.v` 原为空，本轮建立首次板级默认行为；既有 controller/wrapper 行为未改变。
- legacy path：既有 XSim controller TB/Tcl 未修改，不受 Top 默认构建影响。
- 风险：新增 RTL 尚未由真实 Verilog 编译器、Vivado 或仿真验证；XDC 首板属性尚未工具接受。
- 人工重点 review：UART bit timing、parser completion、ACK/request 顺序、reset、Top generic、XDC config properties。
- Git 审查：重点查看上述 3 个工程文件；006 prompt 的 1 行 diff 属用户输入。
- 额外自主写入：无超出 GOAL 的文件。

## 15. 验证情况

- 完成授权范围内的结构化静态自检，所有最终检查项 PASS。
- 使用 `fpga-rtl-rules` 约束端口后缀、参数、FSM、非阻塞赋值、valid-ready 保持、CDC 与例化格式。
- 未修改旧 RTL 的既有行尾空白；静态审计只要求本轮修改文件无新增空白问题。

## 16. 未执行事项

- 未运行 Vivado、`xvlog`、`xelab`、XSim。
- 未运行综合、实现、DRC、timing、bitstream。
- 未生成 Golden/Application `.bit`、MCS/BIN。
- 未连接 Hardware Manager、未写 Flash、未上板、未发送真实 UART/UDP。
- 未修改 Python、MIG/IP、ILA。
- 未执行 git add/commit/push/reset/clean/stash 或其它 Git 写。

## 17. 风险与注意事项

- 结构化静态检查不能代替 HDL parser；语法/elaboration 风险仍存在。
- Application 镜像必须显式设置 `PARAM_IMAGE_IS_APPLICATION=1`；否则两个 build 都显示 Golden 1 Hz。
- `CONFIGRATE=12`、`TIMER_CFG=0x00050000` 与 fallback property 必须在 Vivado 2018.3 中查询并审计实际 bitstream。
- UART 接口的板外收发器极性/连接虽然 pin 已由人工确认，仍需实板回环或终端测试。
- UART ACK 是单字节 `0x06`，不是文本；主机工具必须按 binary byte 接收。
- `M[2:0]=001` 是人工硬件事实，XDC 的 `CONFIG_MODE SPIx4` 不会改变物理绑带。
- 真实 IPROG 会中断当前设计，任何日志必须在触发前完成传输。

## 18. 下一轮建议

单独开启 S7 Linux Vivado 编译/XSim gate：

1. 新增 Top/UART 自检 TB 与独立 Tcl/Shell 入口。
2. 测试 reset、错误命令、超时、`BOOT APP`、`BOOT GOLDEN`、ACK、backpressure、地址不覆盖。
3. 使用 UNISIM ICAPE2 检查最终 WBSTAR 分别为 `0x00800000` 和 `0x00000000`。
4. 运行 Vivado 2018.3 `xvlog/xelab/xsim`，保存日志/WDB。
5. 仍不生成 bitstream；综合/实现/bitstream 另设后续授权 gate。

## 19. 待授权事项

- S7：允许修改 UART/Top TB/Tcl/Shell，并运行 Vivado XSim。
- 后续 build gate：允许 synth/impl、查询 XDC properties、DRC/timing。
- bitstream/MCS/Hardware Manager/Flash/上板继续需要独立明确授权。

## 20. FPGA 调试 yes/no 状态

- 是否修改 RTL：yes；实现 Top、UART RX/TX/parser/boot request、LED，006 prompt 明确授权。风险是尚无 HDL 编译/仿真证据。
- 是否修改 XDC：yes；新增 clock/UART pins/fallback/timer/compress，并将 CONFIGRATE 50 改为 12，006 prompt 明确授权。风险是尚未由 Vivado 接受。
- 是否修改 Tcl：no。
- 是否修改 Python：no。
- 是否运行 Vivado：no，prompt 明确禁止。
- 是否生成 bitstream：no。
- 是否上板：no。
- 是否发送真实 UDP 包：no。
- 是否修改 MIG/IP：no。

## 21. 最终 Git 状态

最终 `git status --short`：

```text
 M ai_workflow/HANDOFF_CURRENT.md
 M ai_workflow/TASK_INDEX.md
 M ai_workflow/tasks/20260717_multiboot_ctrl_fsm/TASK_STATE.md
 M constraints/PIN.xdc
 M prompts/codex/006_board_level_top_uart_trigger_integration_def_impl.md
 M rtl/hdl/user/Top.v
?? ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260719_205547_board_top_uart_integration_static_report.md
?? rtl/hdl/user/multiboot/uart_boot_trigger.v
```

最终 `git diff --stat`：

```text
 ai_workflow/HANDOFF_CURRENT.md                     |  20 +--
 ai_workflow/TASK_INDEX.md                          |   2 +-
 .../20260717_multiboot_ctrl_fsm/TASK_STATE.md      |  22 +--
 constraints/PIN.xdc                                |  15 +-
 ..._level_top_uart_trigger_integration_def_impl.md |   1 +
 rtl/hdl/user/Top.v                                 | 157 +++++++++++++++++++++
 6 files changed, 195 insertions(+), 22 deletions(-)
```

- 普通 `git diff --stat` 不包含未跟踪的 488 行 `uart_boot_trigger.v` 和本报告，已由 `git status --short` 与 `wc -l` 单独核验。
- 006 prompt 的 1 行 diff 是用户开工前修改，本轮未编辑。
- `git diff --check` 最终通过；仅输出上述两个既有 CRLF 文件的换行提示。
- 未执行任何 Git 写操作。
