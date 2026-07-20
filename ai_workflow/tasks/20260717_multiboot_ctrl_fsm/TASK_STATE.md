# 20260717_multiboot_ctrl_fsm 任务状态（纯快照）

> 本文件是本任务状态的唯一事实来源（SSOT），agent 专用；硬上限 150 行。
> 轮次历史 = 本目录 `reports/` + git log。任务定义见 `TASK.md`；验收以最新 prompt 为准。

## 1. 当前状态

- ACTIVE。阶段：S7 Linux Vivado 编译/XSim gate 已完成，S8 逻辑梳理报告完成；Top/UART 自检仿真 PASS。
- 唯一下一步见 §6。

## 2. 关键事实（每条一行，证据 = report/commit 指针）

### 继承基线

- 分支 `dev`，S7 本轮基线 `3ebbc88 增加uart触发源+multiboot逻辑-未上板卡验证`；证据：本轮 S7 报告。
- 抽象 controller 与前置 XSim PASS 已提交；证据：`reports/20260717_021312_multiboot_ctrl_fsm_xsim_report.md`。

### 本轮新增事实

- 已新增 `multiboot_icape2_wrapper`，边界为抽象命令流到 `ICAPE2` X32 原语，原 `multiboot_ctrl` 未修改；证据：`reports/20260719_024339_multiboot_icape2_xsim_report.md`。
- wrapper 在实际写拍驱动 `CSIB=0`、`RDWRB=0`，并对 32-bit 配置字每个 byte 内做 bit-reversal；证据：本轮报告。
- `icap_enable_i` 负责授权/暂停写入；ICAPE2 本身没有 ready 输出，reset 或 enable 低时 wrapper 对 controller backpressure 且 `CSIB=1`；证据：本轮报告。
- 自检 TB 覆盖模型初始化、8-word 顺序/数量、ICAP 控制与物理数据、backpressure、busy 新请求、执行中 reset、UNISIM WBSTAR 和 IPROG 解码；证据：本轮报告。
- 最终真实 run `20260719_024313_xsim-multiboot-ctrl` 为 SUCCESS，日志含 `RESULT=PASS`；证据：本轮报告。
- xelab 日志明确编译 `unisims_ver.SIM_CONFIGE2` 与 `unisims_ver.ICAPE2`；证据：本轮报告。
- UNISIM 模型观测到 `WBSTAR=0x00200000` 与 IPROG pulse；证据：本轮报告。
- WDB 为 `_artifacts/common_vivado/20260719_024313_xsim-multiboot-ctrl/multiboot_ctrl.wdb`，44104 bytes；证据：本轮报告。
- `_runs/latest` 与 `_artifacts/latest` 均指向 `common_vivado/20260719_024313_xsim-multiboot-ctrl`；证据：本轮报告。
- 本轮未改 RTL/Tcl/TB、未运行 Vivado，仅新增当前实现逻辑梳理报告；证据：`reports/20260719_183228_multiboot_logic_sortout_report.md`。
- S5 固定目标为 `xc7a35tfgg484-2` + `N25Q128A13ESE40G` 16 MiB + Master SPI x4 / 24-bit byte addressing；证据：`reports/20260719_194352_multiboot_flash_layout_solution_report.md`。
- Golden offset/WBSTAR 为 `0x00000000`，Application offset/WBSTAR 为 `0x00800000`；单镜像规划上限 4 MiB，中间保留 4 MiB guard；证据：本轮 S5 报告。
- 默认上电运行 Golden；第一阶段由 UART 运行时触发 ICAPE2，两个 bitstream 均不嵌入自动 NEXT_CONFIG_ADDR/IPROG；Ethernet 触发后移；证据：本轮 S5 报告。
- S5 只完成方案定义，未改代码、未运行 Vivado、未生成 bitstream/MCS、未上板；证据：本轮 S5 报告。
- S6 板级事实已固定：50 MHz W19、低有效 reset N15、UART1 TX N17/RX P17 LVCMOS33、Master SPI x4 `M[2:0]=001`；证据：`reports/20260719_205547_board_top_uart_integration_static_report.md`。
- `Top.v` 已接入 UART trigger → controller → ICAPE2 wrapper，默认 Golden 1 Hz，参数化 Application 4 Hz；证据：本轮 S6 报告。
- UART 接受 `BOOT APP\r\n` / `BOOT GOLDEN\r\n`，先回 ACK `0x06` 再发 valid-ready request，含 RX CDC、frame error 和 500 ms partial-command timeout；证据：本轮 S6 报告。
- XDC 已补 50 MHz clock/UART pins，并定义 SPIx4、CONFIGRATE 12、fallback、timer、no compression；未设置 NEXT_CONFIG；证据：本轮 S6 报告。
- 本轮非 Vivado 结构化静态检查 PASS；未发现可用开源 HDL 编译器，未运行 Vivado/编译/XSim；证据：本轮 S6 报告。
- 新增 Top/UART XSim 入口：`sim/tb/tb_top_uart_multiboot.v`、`tcl/sim/xsim_top_uart_multiboot.tcl`、shell 命令 `xsim-top-uart-multiboot`；证据：`reports/20260719_232416_top_uart_xsim_report.md`。
- S7 原始真实 run `20260719_232340_xsim-top-uart-multiboot` 为 SUCCESS，日志含 `RESULT=PASS`；证据：本轮 S7 报告。
- 当前 latest 真实 run `20260719_235747_xsim-top-uart-multiboot` 也为 SUCCESS，日志含 `RESULT=PASS`；证据：`reports/20260720_003126_top_uart_logic_and_tb_arrangement_report.md`。
- xelab 日志明确编译 `uart_boot_trigger`、`Top`、`multiboot_ctrl`、`multiboot_icape2_wrapper`、`unisims_ver.ICAPE2/SIM_CONFIGE2`；证据：本轮 S7 报告。
- S7 自检覆盖 UART 非法命令拒绝、partial-command timeout、ACK `0x06`、valid-ready backpressure hold、APP/GOLDEN 地址、ICAP 8-word 序列、byte bit-reversal、UNISIM WBSTAR/IPROG；证据：本轮 S7 报告。
- 当前 latest WDB 为 `_artifacts/common_vivado/20260719_235747_xsim-top-uart-multiboot/top_uart_multiboot.wdb`，660151 bytes；`_runs/latest` 与 `_artifacts/latest` 均指向该成功 run；证据：本轮 S8 梳理报告。
- 已完成顶层/子模块调用逻辑、数据走向、testbench 激励与推进下一阶段判据说明；证据：`reports/20260720_003126_top_uart_logic_and_tb_arrangement_report.md`。

## 3. 阶段门（每 gate 一行：Planned / In Progress / Done）

- S0 Done — 任务初始化与边界登记。
- S1 Done — 抽象 FSM / TB / Tcl / Shell 入口实现。
- S2 Done — Linux XSim 抽象功能仿真运行通过。
- S3 Done — 抽象仿真状态与报告收口。
- S4 Done — ICAPE2 wrapper、UNISIM elaboration、自检 XSim 和报告收口。
- S5 Done — Flash 模式、双镜像布局、WBSTAR 编码、UART 首发触发和恢复方案定义。
- S6 Done — 板级 Top/UART/LED/XDC 实现与非 EDA 结构化静态自检。
- S7 Done — Linux Vivado `xvlog/xelab/xsim` Top/UART 自检仿真。
- S8 Done — 当前 Top/UART 集成逻辑与 testbench 安排梳理报告。

## 4. 证据边界 / 禁止误称

- 本轮证明 controller → wrapper → ICAPE2 UNISIM 的接口、控制节拍、位序和命令解码仿真通过。
- S5 只定义 Flash 布局/地址方案，不证明实际 Flash 内容、bitstream、板级配置模式、时钟约束、真实 FPGA 重配置或 fallback 成功。
- S6 静态 PASS 不等于 Verilog 编译、XSim、综合/实现、bitstream 或上板 PASS。
- S7 XSim PASS 证明 Top/UART/controller/wrapper/ICAPE2 UNISIM 在仿真参数下通过自检；不证明综合、实现、XDC property、bitstream、Flash、真实 UART 或实板重配置。
- `req_addr_i` 原样写入 WBSTAR；本平台 N25Q128 24-bit SPI 方案固定为 Flash byte offset，不能外推到 32-bit SPI/BPI。
- XSim 中观察到 UNISIM IPROG pulse 不等于真实器件已重配置。
- `_artifacts/latest` 只能指向成功且产物完整的 artifact 目录。

## 5. 待补证据 / 待决策 / 待授权

- 人工审查前置 wrapper/TB/Tcl diff 和报告后决定是否提交。
- 人工审查 S7 Top/UART TB/Tcl/Shell diff 和扩大修改说明；Application build 必须设置 `PARAM_IMAGE_IS_APPLICATION=1`。
- `CONFIGRATE=12`、`TIMER_CFG=0x00050000`、fallback/no-compress 均需后续 Vivado property/bitstream/实板复核。
- bitstream、MCS/BIN、Flash 写入和 Hardware Manager 上板验证仍需单独授权。

## 6. 唯一下一步

人工审查 `reports/20260720_003126_top_uart_logic_and_tb_arrangement_report.md`；确认理解与证据边界后另起 S9 Vivado build/property 审计 gate。

## 7. 仓库要点

- S8 开工时唯一脏改动为未跟踪 `prompts/codex/008_multiboot_new_top_uart_integrated_selftest_testbench_arrange.md`；本轮未修改、未回滚。
- 本轮不执行 git add/commit/push/reset/clean/stash，不运行综合/实现/bitstream，不上板。
