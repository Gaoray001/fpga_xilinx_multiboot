# 报告：结合硬件事实的 Multiboot Flash 布局与完整方案定义

- AI 模型类型：Codex / GPT-5 coding agent
- 时间戳：20260719_194352
- 本轮任务：读取并执行 `prompts/codex/005_complete_solution_design_combined_with_hardware_facts.md`
- 本轮 gate：S5 Flash 模式 / 镜像布局 / WBSTAR 编码定义
- 最终结论：S5 方案定义完成；本轮未推进代码、Vivado、bitstream、Flash 或上板。

## 1. git baseline

- branch：`dev`
- recent log：
  - `27bbdef 增加multiboot逻辑实现理解`
  - `ff9adfc 增加multiboot原语ICAPE2`
  - `076720e 增加最小multiboot逻辑实现`
  - `e9a8047 Xsim冒烟测试-可观察vivado仿真波形`
  - `f8eb58d first commit`
- 开工 `git status --short`：

```text
A  prompts/codex/005_complete_solution_design_combined_with_hardware_facts.md
```

- 开工 `git diff --stat`：空；005 prompt 已在 index 中，因此补查 `git diff --cached --stat` 为 1 file / 92 insertions。
- 005 prompt 是用户已有 staged 文件，本轮未修改、未取消暂存。

## 2. 输入事实摘要

- 精确 FPGA：`xc7a35tfgg484-2`，即 Artix-7 35T，不是 Zynq-7000 器件。
- 精确 SPI Flash：`N25Q128A13ESE40G`，128 Mbit / 16 MiB。
- 开发分工：Linux 做 RTL/XSim；Windows Hardware Manager 留待后续上板。
- 第一阶段触发源：UART；Ethernet 触发明确后移。
- 前置 ICAPE2 UNISIM XSim 已 PASS，但不证明 Flash、bitstream 或真实重配置。

## 3. latest report 发现

- 当前任务 `reports/` 按时间戳排序的开工最新报告为：
  `20260719_183228_multiboot_logic_sortout_report.md`。
- 与 prompt 指定的前置报告一致，无 latest report 漂移。
- `TASK_INDEX.md` 的下一步也指向该报告后的 S5 定义，本轮承接关系一致。

## 4. 边界自检

- WRITE_ALLOW / HARD_BOUNDARY：只允许新增当前任务报告、更新 `ai_workflow` 状态文件；禁止代码实现。
- RUN_POLICY：R1；只运行只读 Git/Shell 查询，不运行 Vivado/EDA，不生成工程产物。
- OVERRIDE_BOUNDARY：prompt 未提供，按默认边界执行。
- hard-readonly：`ai_workflow/AGENT_RULES.md`、任务 `ACCEPTANCE.md` 只读，均未修改。
- 实际工程代码修改：0。
- 实际状态/报告修改：本报告、`TASK_STATE.md`、`HANDOFF_CURRENT.md`、`TASK_INDEX.md`。
- 实际命令：`sed`、`rg`、`find`、`file`、`ls`、`wc`、`awk`、`date` 与只读 Git 查询。
- 额外只读动作：查询 AMD/Xilinx 与 Micron 官方资料，并读取本机 Vivado 2018.3 cfgmem 数据库；无外部写入。
- 是否触碰禁止项：no。
- 是否修改 hard-readonly：no。
- 是否存在额外自主修改：no。
- 是否越界：no。

## 5. 硬件事实与依据

### 5.1 FPGA 与 bitstream 容量

AMD UG470 Table 1-1 给出 7A35T 完整配置 bitstream 长度为 `17,536,096 bits`，换算为：

```text
17,536,096 / 8 = 2,192,012 bytes = 0x0021728C ≈ 2.0905 MiB
```

UG470 同时给出的最低配置 Flash 容量为 32 Mbit。当前 128 Mbit Flash 足以容纳两个未压缩 7A35T 镜像及保护间隔。依据：[UG470 v1.17](https://docs.amd.com/api/khub/documents/FOs3lXmlcWxBhTIFxVKyGA/content)。

### 5.2 Flash 型号解码

Micron 官方 N25Q 编码表确认：

- `128` = 128 Mbit / 16 MiB；
- `3` = 2.7–3.6 V；
- `E` = uniform array；
- 器件为 byte-addressable Multi-I/O SPI NOR。

依据：[Micron Serial NOR Flash Part Numbering System](https://www.micron.com/content/dam/micron/global/public/products/part-numbering-guide/numnor.pdf)。

本机 Vivado 2018.3 只读数据库进一步给出：

- `N25Q128` 容量 `134217728 bits`；
- 支持 x2/x4 read；
- tool-side sector size 为 `65536 bytes`；
- `xc7a35t` 可选择 `mt25ql128-spi-x1_x2_x4`，legacy alias 为 `n25q128-3.3v-spi-x1_x2_x4`。

这些是工具兼容性证据；上板前仍必须读取实际器件 JEDEC ID，并确认 Hardware Manager 选中的 cfgmem part 与焊接器件匹配。

### 5.3 仓库板级约束

`constraints/PIN.xdc` 当前声明：

```tcl
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
```

这与 3.3 V N25Q128 和目标 Master SPI x4 方案方向一致。但 XDC 不能证明板上 `M[2:0]` 配置模式绑带、SPI 走线或 CCLK 信号质量正确；这些仍需原理图/实板确认。AMD 对 Master SPI 硬件连接与 mode pin 的说明见 [XAPP586](https://docs.amd.com/r/en-US/xapp586-spi-flash/SPI-Flash-Configuration-Interface)。

## 6. S5 固定方案

### 6.1 假设表填写结果

| 项目 | 本轮固定值 |
|---|---|
| 目标 FPGA | `xc7a35tfgg484-2` / Artix-7 35T |
| 配置模式 | Master SPI x4，N25Q128 24-bit byte addressing |
| Flash 型号 | `N25Q128A13ESE40G`，3.3 V |
| Flash 容量 | 128 Mbit = 16 MiB，byte range `0x000000–0xFFFFFF` |
| golden byte offset | `0x00000000` |
| application byte offset | `0x00800000`（8 MiB） |
| golden WBSTAR payload | `0x00000000` |
| application WBSTAR payload | `0x00800000` |
| 器件原始完整 bitstream | `2,192,012 bytes`，约 2.09 MiB |
| 规划单镜像最大值 | `0x00400000` = 4 MiB；构建后必须检查实际文件小于该值 |
| 镜像起点间隔 | 8 MiB |
| 显式安全空洞 | 4 MiB，`0x00400000–0x007FFFFF` |
| 默认启动镜像 | Golden；上电和 PROGRAM_B 均从 Flash address 0 启动 |
| 第一阶段触发 | UART 触发运行时 ICAPE2 IPROG |
| 失败恢复 | 配置 fallback + watchdog 回 Golden；有效但异常 Application 可通过 UART、PROGRAM_B 或掉电回 Golden |

### 6.2 Flash 地址图

```text
0x00000000  +------------------------------+
            | Golden slot, 4 MiB           |
0x003FFFFF  +------------------------------+
0x00400000  | Guard/reserved, 4 MiB        |
0x007FFFFF  +------------------------------+
0x00800000  | Application slot, 4 MiB      |
0x00BFFFFF  +------------------------------+
0x00C00000  | Future/reserved, 4 MiB       |
0x00FFFFFF  +------------------------------+
```

设计理由：

- 两个镜像起点均按 64 KiB sector、256-byte 边界对齐。
- 4 MiB slot 明显大于 7A35T 未压缩完整配置数据约 2.09 MiB，允许 `.bit` 头和后续小幅变化。
- Golden 与 Application 之间保留完整 4 MiB 空洞，降低地址误算或超长产物覆盖另一镜像的风险。
- Application 后仍保留 4 MiB，后续可用于第二更新槽、元数据或 barrier/timer image，但本轮不分配用途。

### 6.3 WBSTAR 编码结论

N25Q128 容量恰为 16 MiB，使用 24-bit SPI byte address，不需要 32-bit address mode。UG470 Table 7-2 规定 Master SPI 从 `WBSTAR[23:0]` 串行发送起始地址；其 32-bit addressing 的 `address[31:8]` 特例不适用于本器件。因此本方案采用：

```text
WBSTAR payload = Flash byte offset

Golden      0x00000000 -> WBSTAR 0x00000000
Application 0x00800000 -> WBSTAR 0x00800000
```

当前 `multiboot_ctrl.req_addr_i` 原样写入 WBSTAR，因此后续顶层应传上述 payload 常量，不再移位、不除以 4，也不做 x4 bus-width 缩放。SPI x4 只改变数据传输宽度，不改变 Flash byte address 语义。AMD 的 7 Series SPI MultiBoot 示例也直接用 byte offset 作为 `NEXT_CONFIG_ADDR` / Flash load address，见 [XAPP1247](https://docs.amd.com/api/khub/documents/5P~3UdOsly0vpmX42taDfg/content)。

注意：前置 XSim 使用的 `0x00200000` 只是接口仿真样例，不再作为本板 Application 地址。

## 7. Golden / Application 两个 LED 工程定义

### 7.1 Golden image

- LED：慢闪，建议 1 Hz，作为 Golden 可视身份。
- 含 UART RX/TX、命令解析、`multiboot_ctrl`、`multiboot_icape2_wrapper`。
- 接收 `BOOT APP\r\n` 后映射到 WBSTAR `0x00800000`。
- UART 先返回 ACK，等待 TX 完成，再提交 ICAPE2 请求，避免 ACK 被重配置截断。
- 不设置 `BITSTREAM.CONFIG.NEXT_CONFIG_ADDR`，不嵌入自动 IPROG；Golden 上电后保持运行，等待 UART 命令。

### 7.2 Application image

- LED：快闪，建议 4 Hz，和 Golden 肉眼可区分。
- 第一版同样保留 UART 与 Multiboot 控制链。
- 接收 `BOOT GOLDEN\r\n` 后映射到 WBSTAR `0x00000000`，用于正常软件回滚。
- 同样不嵌入自动 IPROG，避免 boot loop。

### 7.3 UART 触发契约

- 建议 UART 参数：115200, 8N1；最终可用波特率取决于尚未确认的板载输入时钟。
- 只接受完整精确命令和行结束符；部分命令、超时帧、busy 期间命令均不得触发。
- 命令解析完成后仅在 `req_ready_o=1` 时提交一次 request。
- `req_valid_i && req_ready_o` 成立后锁存目标；busy 期间禁止覆盖。
- 异步 UART RX 必须做 CDC 处理；后续新增 RTL 按 `fpga-rtl-rules` 的端口、复位、FSM 和 valid-ready 规则实现。
- Ethernet 触发不进入第一版 Top，不与 UART 同轮实现；未来只复用同一个抽象 boot request 接口。

当前仓库没有 UART 管脚约束，也没有输入时钟频率约束；因此 UART 波特率分频值、LED 计数器和 XDC pin 不能在本轮固化为硬件事实。

## 8. bitstream 属性策略

两个镜像后续均应具有：

```tcl
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGFALLBACK ENABLE [current_design]
set_property BITSTREAM.CONFIG.TIMER_CFG 0x00050000 [current_design]
```

策略说明：

- `NEXT_CONFIG_ADDR`：两个镜像均不设置；运行时由 ICAPE2 写 WBSTAR。
- `NEXT_CONFIG_REBOOT`：不启用；禁止配置完成后自动 IPROG。
- `TIMER_CFG=0x00050000`：作为第一版约 1.3 s 的配置 watchdog 候选值。UG470 说明 watchdog 周期约 4 us；该值需在下一 gate 通过生成 bitstream 后检查 TIMER 字段，并按实际配置耗时复核。
- `CONFIGRATE`：现有 XDC 的 50 MHz 尚无板级信号完整性证据。首次上板建议先使用合法保守值 12 MHz；稳定后再单独验证 50 MHz。该修改留给 S6/S7 授权轮。
- `COMPRESS`：首次验证建议关闭，以固定最坏容量并简化地址审计；两个未压缩镜像仍远小于 16 MiB。稳定后可再评估压缩。

UG470 明确要求配置 watchdog 覆盖无效地址、缺失 sync 或不完整 bitstream，并要求 timer 覆盖完整配置至 startup 的时间；XAPP1247 也指出 SPI update 区损坏时需要 watchdog 触发 fallback。数值在真实 bitstream/时钟证据前只能称“方案候选”，不能称已验证。

## 9. 首次烧写步骤（后续 Windows gate）

本节是待执行操作单，不代表本轮已执行：

1. 获取板卡原理图或人工确认：`M[2:0]` 为 Master SPI、SPI x4 连接、UART RX/TX pins、电平、输入时钟频率。
2. 分别实现并构建 Golden 1 Hz 与 Application 4 Hz；两个设计均使用 `xc7a35tfgg484-2`。
3. 检查每个 `.bit` 实际大小 `< 0x00400000`，并审计 bitstream properties；重点确认没有 embedded `NEXT_CONFIG_ADDR/IPROG`，但有 SPIx4、fallback 和 timer。
4. 生成 128 Mbit SPIx4 MCS，逻辑装载关系为：

```text
up 0x00000000 golden.bit
up 0x00800000 application.bit
```

5. 在 Vivado 2018.3 Hardware Manager 中读取实际 JEDEC ID；选择 `mt25ql128-spi-x1_x2_x4`，或其 legacy alias `n25q128-3.3v-spi-x1_x2_x4`，不得只凭名称跳过 ID 校验。
6. 擦除、program、verify 完整 MCS；保存 Hardware Manager 日志。
7. 断电重上电，预期 Golden 1 Hz 慢闪。
8. UART 发送 `BOOT APP\r\n`，预期 DONE/INIT_B 出现重配置过程，最终 Application 4 Hz 快闪。
9. UART 发送 `BOOT GOLDEN\r\n`，预期恢复 1 Hz 慢闪。
10. 另起明确授权轮做破坏性 fallback 测试：损坏/擦除 Application 区后触发 BOOT APP，验证 watchdog/fallback 回 Golden；不得损坏 Golden 区。

示意 `write_cfgmem` 目标参数为 `-format mcs -size 16 -interface SPIx4` 加上述两个 `-loadbit` 地址。实际命令必须在拿到真实 `.bit` 路径后由 S7/S8 生成并审查，本轮不写脚本、不运行。

## 10. 回滚与恢复步骤

按风险从低到高：

1. 正常回滚：Application UART 命令 `BOOT GOLDEN`，ICAPE2 写 WBSTAR 0 后 IPROG。
2. Application 有效但逻辑异常：拉低 PROGRAM_B 或断电重启；硬件默认从 Flash 0 启动 Golden。
3. Application 配置损坏：配置 watchdog / CRC / IDCODE error 触发 fallback，回 Flash 0 的 Golden。
4. Flash Application 区需修复：保持 Golden 运行，在 Windows Hardware Manager 只更新 Application region；操作前复核地址范围，禁止擦除 Golden slot。
5. Golden 也损坏：通过 JTAG 临时加载已归档的 Golden bitstream，再用 Hardware Manager 重写完整已验证 MCS。这是最后恢复路径，需要独立授权和已保存的 known-good artifacts。

安全要求：Golden slot 在首次验证完成后应视为只读/受保护区；后续远程更新只能写 Application slot。Flash block-protect 的具体寄存器策略尚未定义，不在本轮冒充已完成。

## 11. 本方案证明与不证明

本轮已定义：

- 精确 part、Flash 型号/容量、电压方向和 Master SPI x4 目标模式。
- 双镜像 offset、容量上限、安全空洞和 WBSTAR payload。
- UART 第一阶段触发逻辑边界。
- 默认启动、正常回滚、异常 fallback 和 JTAG 最后恢复路径。
- 首次 MCS/Hardware Manager 操作顺序与验收现象。

本轮未证明：

- 板上 mode pin、UART pin、电平和输入时钟。
- `CONFIGRATE=12/50` 的真实板级裕量。
- `TIMER_CFG=0x00050000` 已正确写入并满足实测超时。
- 两个 LED 工程可综合/实现/时序收敛。
- MCS 可生成、Flash 可 program/verify、ICAPE2 可真实重配置或 fallback。

## 12. 修改摘要与实际改动文件

- 新增本 S5 方案报告。
- 更新任务 SSOT，将 S5 标记为 Done，并登记固定地址方案与下一 gate。
- 更新第一屏 handoff 和任务索引的下一步/报告指针。
- 未修改 RTL、XDC、Tcl、Shell、Python、IP 或工程文件。

实际改动文件：

- `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260719_194352_multiboot_flash_layout_solution_report.md`
- `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/TASK_STATE.md`
- `ai_workflow/HANDOFF_CURRENT.md`
- `ai_workflow/TASK_INDEX.md`

## 13. 额外自主修改说明

- 无额外自主写入。
- 只读查询官方资料和本机 Vivado cfgmem 数据库，用于验证地址语义、bitstream 容量与器件工具兼容名。
- 收益：避免把 SPI x4 误当作地址缩放，也避免继续使用前置仿真样例 `0x00200000`。
- 风险/默认行为/legacy path：无修改、无影响。

## 14. 验证情况

- 完成 Git baseline、latest report、硬件约束、part/Flash 数据库、官方文档交叉检查。
- 完成容量计算与地址区间人工审计：所有区间在 `0x000000–0xFFFFFF` 内且不重叠。
- 未做动态验证；本轮是设计定义 gate。

## 15. 未执行事项

- 未修改或新增代码。
- 未运行 Vivado/XSim/synth/impl/bit。
- 未生成 `.bit`、`.bin`、`.mcs`。
- 未打开 Hardware Manager、未连接板卡、未读 JEDEC ID、未写 Flash。
- 未进行 UART 或 Ethernet 实测。
- 未执行 git add/commit/push/reset/clean/stash。

## 16. 风险与注意事项

- `CONFIG_MODE SPIx4` 是设计/XDC 目标，不等于板上 mode straps 已证实。
- UART 管脚和板载输入时钟缺失，会阻塞 S6 的正确 Top/XDC 实现。
- Flash 工具兼容名是本地 Vivado 2018.3 数据库映射，真实器件必须以 JEDEC ID 为准。
- watchdog 值需通过 bitstream 反查和上板失效注入验证；只有 `CONFIGFALLBACK ENABLE` 不足以覆盖 SPI sync 丢失场景。
- Golden 必须保持 address 0 且禁止远程覆盖；否则 power-cycle/fallback 的恢复承诺失效。
- 现有 `Top.v` 为空，方案尚未接入板级设计。

## 17. 下一轮建议

S6 只做板级 Top + UART 触发集成定义/实现：

1. 人工提供或确认输入时钟频率、UART RX/TX pin 与 IO voltage、板上 `M[2:0]` straps。
2. 实现 Golden/Application 两个可区分 LED 模式和 UART boot command adapter。
3. Top 接入既有 controller/wrapper，固定 Application payload `0x00800000`、Golden payload `0x00000000`。
4. 补齐 UART/clock XDC 与 ICAP 时钟约束，先做静态 review 和 XSim；仍不生成 bitstream，除非该轮明确授权。

Ethernet 触发继续后移，不与 S6 混做。

## 18. 待授权事项

- S6：允许修改 Top/UART/LED RTL、XDC 和相应 TB/Tcl。
- S7：明确授权 synth/impl/bit，并验证属性、尺寸、DRC、时序和 TIMER 字段。
- S8：明确授权生成 MCS、Windows Hardware Manager、Flash program/verify 与板级重配置。
- S9：明确授权破坏 Application 区的 fallback 失效注入测试。

## 19. FPGA 调试 yes/no 状态

- 是否修改 RTL：no。
- 是否修改 XDC：no。
- 是否修改 Tcl：no。
- 是否修改 Python：no。
- 是否运行 Vivado：no。
- 是否生成 bitstream：no。
- 是否上板：no。
- 是否发送真实 UDP 包：no。
- 是否修改 MIG/IP：no。

## 20. 最终 Git 状态

最终 `git status --short`：

```text
 M ai_workflow/HANDOFF_CURRENT.md
 M ai_workflow/TASK_INDEX.md
 M ai_workflow/tasks/20260717_multiboot_ctrl_fsm/TASK_STATE.md
A  prompts/codex/005_complete_solution_design_combined_with_hardware_facts.md
?? ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260719_194352_multiboot_flash_layout_solution_report.md
```

最终 `git diff --stat`：

```text
 ai_workflow/HANDOFF_CURRENT.md                     | 17 ++++++++++-------
 ai_workflow/TASK_INDEX.md                          |  2 +-
 .../20260717_multiboot_ctrl_fsm/TASK_STATE.md      | 22 ++++++++++++++--------
 3 files changed, 25 insertions(+), 16 deletions(-)
```

- 新增未跟踪 report 不会出现在普通 `git diff --stat` 中，已由 `git status --short` 核验。
- 005 prompt 是用户预先 staged 的新增文件，本轮未修改其内容或 index 状态。
- `git diff --check` 通过；只有该 prompt 的既有 CRLF 提示，无本轮 workflow/report whitespace error。
