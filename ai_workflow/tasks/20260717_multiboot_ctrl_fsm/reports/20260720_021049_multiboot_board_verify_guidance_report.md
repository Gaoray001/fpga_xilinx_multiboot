# 报告：Multiboot 上板验证指导与 WDB 打开脚本

- AI 模型类型：Codex / GPT-5 coding agent
- 时间戳：20260720_021049
- 本轮任务：读取并执行 `prompts/codex/009_push_multiboot_board_verify.md`
- 本轮性质：S9 上板验证阶段指导说明 + 新增 latest WDB 打开脚本
- 最终结论：已新增 `scripts/open_latest_wbd.sh`；已给出 Golden/Application 双 bit、MCS 合成、Flash 烧录和 UART/LED 实板验证指导。本轮没有执行 Vivado GUI、Hardware Manager、烧录、上板或 git 写操作。

## 1. git baseline

- branch：`dev`
- baseline commit：`7d72a19 增加top层串口触发源+multiboot+仿真逻辑梳理+可综合生成比特流`
- recent log：
  - `7d72a19 增加top层串口触发源+multiboot+仿真逻辑梳理+可综合生成比特流`
  - `6afa7db 增加top触发源+multiboot逻辑+vivado仿真`
  - `3ebbc88 增加uart触发源+multiboot逻辑-未上板卡验证`
  - `9dc8ee4 硬件板卡边界确定+Top板级实现方案规划`
  - `27bbdef 增加multiboot逻辑实现理解`
- 开工 `git status --short --untracked-files=all`：

```text
?? prompts/codex/009_push_multiboot_board_verify.md
```

- 开工 `git diff --stat`：空。

## 2. 输入事实摘要

- 活跃任务：`ai_workflow/tasks/20260717_multiboot_ctrl_fsm`。
- 前置报告：`reports/20260720_003126_top_uart_logic_and_tb_arrangement_report.md`。
- 人工事实：已执行 `scripts/vivado2018_common.sh`，成功生成 bit 流，无时序报错。
- 本轮目标：推进上板卡验证阶段，给出指导说明；新增 `scripts/open_latest_wbd.sh`，可快速打开 `_artifacts/latest/*.wdb` 波形。

## 3. 只读核对到的构建与仿真产物

当前 `_runs/latest`：

```text
_runs/latest -> common_vivado/20260720_014923_full
```

该 full build 的 `summary.txt` / `status.txt` 显示：

- `result: SUCCESS`
- `synth_1 status: synth_design Complete!`
- `impl_1 status: write_bitstream Complete!`
- `bitstream_found=1`
- `part_name: xc7a35tfgg484-2`
- `vivado_part=xc7a35tfgg484-2`

构建产物：

```text
_artifacts/common_vivado/20260720_014923_full/Top.bit        2192126 bytes
_artifacts/common_vivado/20260720_014923_full/Top_routed.dcp 253690 bytes
_artifacts/common_vivado/20260720_014923_full/Top_placed.dcp 230383 bytes
_artifacts/common_vivado/20260720_014923_full/Top_opt.dcp    174896 bytes
_artifacts/common_vivado/20260720_014923_full/Top.dcp        192158 bytes
```

实现报告关键点：

- `impl_timing_summary.rpt`：`All user specified timing constraints are met.`
- WNS = 14.220 ns，TNS = 0.000 ns。
- Hold worst slack = 0.121 ns，THS = 0.000 ns。
- `impl_drc.rpt`：Violations found = 0。

当前 `_artifacts/latest`：

```text
_artifacts/latest -> common_vivado/20260719_235747_xsim-top-uart-multiboot
```

所以 `_artifacts/latest` 仍指向 XSim WDB 产物，不指向 full build bitstream。这是当前脚本行为：full build 生成了 bit，但没有更新 `_artifacts/latest`。

## 4. 边界自检

- WRITE_ALLOW：允许更新 `ai_workflow` 状态文件；允许新增本任务 report；允许新增 `scripts/open_latest_wbd.sh`。
- RUN_POLICY：R1；允许 git 只读查询、shell 非删除命令、tcl 非删除命令。
- HARD_BOUNDARY：允许新增 report，允许更新 `ai_workflow` 状态。
- OVERRIDE_BOUNDARY：未提供。
- 实际修改：新增 `scripts/open_latest_wbd.sh`；新增本报告；更新 `TASK_STATE.md`、`HANDOFF_CURRENT.md`、`TASK_INDEX.md`。
- 实际运行：只读 `sed/rg/find/ls/readlink/date/git`，`chmod +x scripts/open_latest_wbd.sh`，`bash -n scripts/open_latest_wbd.sh`。
- 未运行 Vivado GUI/Hardware Manager。
- 未生成 bitstream/MCS，本轮只读核对已有 full build 产物。
- 未上板、未写 Flash、未发送 UART。
- 未执行 git add/commit/push/reset/clean/stash。
- 是否修改 hard-readonly：no。
- 是否越界：no。

## 5. 新增脚本说明

新增脚本：

```text
scripts/open_latest_wbd.sh
```

用途：

```bash
./scripts/open_latest_wbd.sh
```

行为：

- 定位工程根目录。
- 检查并 source Vivado 2018.3 settings：`/tools/Xilinx/Vivado/2018.3/settings64.sh`，也可用 `VIVADO_SETTINGS=...` 覆盖。
- 在 `_artifacts/latest` 下查找 `.wdb`。
- 若同目录存在 `.wcfg`，同时打开 wave config。
- 调用 `vivado -mode gui` 打开 wave database。

本轮只执行了：

```bash
bash -n scripts/open_latest_wbd.sh
```

语法检查 PASS。没有实际启动 Vivado GUI。

注意：脚本名称按 prompt 写为 `open_latest_wbd.sh`，但打开的是 `.wdb` 波形文件。

## 6. 两个 bit 与 Flash 烧录指导

当前只读核对只看到一个 `Top.bit`，没有看到已归档命名的 `golden.bit`、`application.bit` 或合并后的 `.mcs`。因此下面是建议执行流程，不是本轮已完成事实。

### 6.1 先区分 Golden 与 Application bit

Golden bit：

- 使用默认 `PARAM_IMAGE_IS_APPLICATION=0` 构建。
- LED 预期为 1 Hz。
- 当前 `_artifacts/common_vivado/20260720_014923_full/Top.bit` 从现有证据看只能作为“默认 Top bit / Golden 候选”，不能自动代表 Application。

Application bit：

- 必须设置 Top generic：

```tcl
set_property generic {PARAM_IMAGE_IS_APPLICATION=1} [current_fileset]
```

- LED 预期为 4 Hz。
- 当前构建脚本未见自动透传 `PARAM_IMAGE_IS_APPLICATION=1` 的机制；建议另起小 gate 增加 Application build 入口，或在 Vivado GUI/Tcl 中手动设置 generic 后重新综合实现并导出 `application.bit`。

建议归档命名：

```text
golden.bit       -> WBSTAR/Flash offset 0x00000000
application.bit  -> WBSTAR/Flash offset 0x00800000
```

### 6.2 用两个 bit 合成 SPI Flash MCS

目标 Flash：`N25Q128A13ESE40G`，16 MiB。目标模式：Master SPI x4，板卡绑带 `M[2:0]=001`。

推荐地址：

```text
Golden      0x00000000
Application 0x00800000
```

Vivado Tcl 参考命令：

```tcl
write_cfgmem -force \
  -format mcs \
  -size 16 \
  -interface SPIx4 \
  -loadbit {up 0x00000000 golden.bit up 0x00800000 application.bit} \
  multiboot_s5_dual_image.mcs
```

生成后要检查：

- `.mcs` 文件存在且大小非 0。
- 两个 bitstream 的地址没有重叠。
- `application.bit` 起始地址确实是 `0x00800000`。
- Golden 和 Application 都不应额外嵌入自动 `NEXT_CONFIG_ADDR` / `NEXT_CONFIG_REBOOT`；当前方案由 UART 运行时 ICAPE2 触发。

### 6.3 直接 JTAG 下载 bit 与 Flash 烧录的区别

直接 JTAG 下载 `.bit`：

- 只写 FPGA SRAM 配置。
- 掉电丢失。
- 适合先做 Golden 或 Application 单镜像冒烟测试。
- 不能验证 SPI Flash multiboot 布局。

烧录 `.mcs` 到 SPI Flash：

- 写入外部 N25Q128。
- 掉电重启后由 Master SPI x4 从 Golden 地址启动。
- 才能验证上电 Golden、UART 触发 Application、再 UART 触发 Golden 的完整链路。

## 7. Hardware Manager 上板操作建议

以下建议在 Windows Vivado Hardware Manager 中执行，符合当前工程分工。

### 7.1 单 bit 冒烟

目的：先证明 FPGA 可被下载、时钟/reset/UART/LED 方向基本可用。

步骤：

1. 连接 JTAG，打开 Vivado Hardware Manager。
2. Open Target / Auto Connect。
3. 选择 `xc7a35t` device。
4. Program Device，选择 `golden.bit` 或当前 `Top.bit`。
5. 观察 LED：默认 Golden 候选应为约 1 Hz。
6. 打开串口工具：115200，8N1，无流控。
7. 发送 `BOOT APP\r\n` 前先确认主机工具能发送 CRLF，ACK 是二进制 `0x06`，不是文本字符串。

单 bit JTAG 冒烟不会验证 Flash multiboot；如果此阶段 UART 触发 IPROG，器件会尝试从 Flash 的 WBSTAR 地址重配置，因此 Flash 未正确烧录时可能重配置失败或 fallback。

### 7.2 Flash 双镜像烧录

GUI 建议：

1. Hardware Manager 连接目标。
2. 右键 FPGA device，选择 Add Configuration Memory Device。
3. 选择与 `N25Q128A13ESE40G` 匹配的 3.3V SPI x4 配置存储器；若不确定，先在 Tcl Console 查询：

```tcl
get_cfgmem_parts *n25q128*
```

4. Program Configuration Memory Device。
5. 选择 `multiboot_s5_dual_image.mcs`。
6. 勾选 erase / program / verify。
7. 烧录完成后 power-cycle 板卡，不只按 soft reset。

Tcl 方向参考，具体 cfgmem part 名称以本机 Vivado 查询为准：

```tcl
open_hw_manager
connect_hw_server
open_hw_target
current_hw_device [lindex [get_hw_devices] 0]
refresh_hw_device [current_hw_device]
get_cfgmem_parts *n25q128*
```

后续 `create_hw_cfgmem` / `program_hw_cfgmem` 的属性名建议由 GUI 生成或从 Vivado Tcl Console 补全，避免手写错 cfgmem part 名称。

## 8. 实板验收观测

理想实板流程：

1. Power-cycle 后默认从 Golden 启动。
2. LED 约 1 Hz，说明 Golden identity 生效。
3. 串口发送精确字节序列：

```text
BOOT APP\r\n
```

4. 主机收到 ACK byte `0x06`。
5. FPGA 发生 IPROG 重配置，串口连接可能短暂中断。
6. 重配置后 LED 约 4 Hz，说明 Application identity 生效。
7. 再发送：

```text
BOOT GOLDEN\r\n
```

8. 收到 ACK `0x06`，重配置后 LED 回到约 1 Hz。

建议记录的证据：

- Hardware Manager program/verify 成功截图或日志。
- MCS 文件路径、大小、生成命令。
- Golden/Application bit 文件路径、构建 run、是否设置 `PARAM_IMAGE_IS_APPLICATION=1`。
- 上电 LED 1 Hz 视频或频率记录。
- 串口发送/接收日志，特别是 ACK `0x06`。
- Application LED 4 Hz 观测。
- 回 Golden 后 LED 1 Hz 观测。

## 9. 当前不能声称的事项

- 不能声称双镜像 MCS 已生成：本轮未发现 `.mcs`。
- 不能声称 Application bit 已生成：本轮未发现明确的 `application.bit` 或带 `PARAM_IMAGE_IS_APPLICATION=1` 的构建证据。
- 不能声称 Flash 已烧录：本轮未运行 Hardware Manager。
- 不能声称实板 multiboot PASS：缺少 LED/UART/Flash verify/重配置日志。

## 10. 修改摘要

- 新增 `scripts/open_latest_wbd.sh`。
- 新增本报告。
- 更新 `TASK_STATE.md`、`HANDOFF_CURRENT.md`、`TASK_INDEX.md`。
- 未修改 RTL/TB/Tcl/XDC/Python。

## 11. 实际改动文件

- `scripts/open_latest_wbd.sh`（新增，可执行）
- `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260720_021049_multiboot_board_verify_guidance_report.md`（新增）
- `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/TASK_STATE.md`
- `ai_workflow/HANDOFF_CURRENT.md`
- `ai_workflow/TASK_INDEX.md`

用户已有输入：

- `prompts/codex/009_push_multiboot_board_verify.md`：开工前未跟踪文件，本轮未修改。

## 12. 额外自主修改说明

本轮额外只读核对了 `_runs/latest`、`_artifacts/latest`、full build summary/status、timing/DRC 报告和 artifact 文件列表。

- 原因：prompt FACT 给出“人工已生成 bit 且无时序报错”，需要把指导说明建立在当前可见产物上。
- 收益：发现 `_runs/latest` 指向 full build，但 `_artifacts/latest` 仍指向 XSim WDB，避免混淆 bitstream 与 WDB latest。
- 风险：只读核对不能替代人工上板日志。
- 默认行为：不影响。
- legacy path：不影响。

## 13. 验证情况

- `bash -n scripts/open_latest_wbd.sh`：PASS。
- 只读确认 `_artifacts/latest/top_uart_multiboot.wdb` 与 `.wcfg` 存在。
- 只读确认 full build result SUCCESS、`Top.bit` 存在、timing met、impl DRC 0。

## 14. 未执行事项

- 未实际运行 `scripts/open_latest_wbd.sh`，避免启动 Vivado GUI。
- 未运行 Vivado build、synth、impl、bitstream。
- 未生成 MCS/BIN。
- 未连接 Hardware Manager。
- 未烧写 Flash。
- 未上板。
- 未发送 UART。
- 未执行 git 写操作。

## 15. 风险与注意事项

- 当前 `Top.bit` 只有单镜像证据，不能替代 Golden/Application 双镜像 MCS。
- Application 镜像必须有 `PARAM_IMAGE_IS_APPLICATION=1` 的构建证据，否则 LED 身份无法区分。
- Flash part 名称应以 Vivado `get_cfgmem_parts *n25q128*` 查询结果为准。
- ACK 是二进制 `0x06`，串口工具可能显示为空或控制字符。
- IPROG 后当前设计会重配置，串口会话和 LED 观测需要考虑重启时间。

## 16. 下一轮建议

人工按本报告执行或审查上板验证。回传 Golden/Application bit 路径、MCS 路径、Hardware Manager program/verify 结果、UART ACK 日志、LED 1 Hz/4 Hz 观测后，另起 S10 实板结果收口 gate。

## 17. 待授权事项

- 若需要自动化：新增 Application build 入口和 MCS 生成脚本。
- 若需要执行：Vivado Hardware Manager、Flash program/verify、串口实测、上板重配置验证。

## 18. FPGA 调试 yes/no 状态

- 是否修改 RTL：no。
- 是否修改 XDC：no。
- 是否修改 Tcl：no。
- 是否修改 Python：no。
- 是否修改 Shell：yes，新增 `scripts/open_latest_wbd.sh`，009 prompt 明确授权。
- 是否运行 Vivado：no。
- 是否生成 bitstream：no，本轮只读核对人工已有 full build bitstream。
- 是否上板：no。
- 是否发送真实 UDP 包：no。
- 是否修改 MIG/IP：no。

## 19. 最终 Git 状态

最终 `git status --short --untracked-files=all`：

```text
 M ai_workflow/HANDOFF_CURRENT.md
 M ai_workflow/TASK_INDEX.md
 M ai_workflow/tasks/20260717_multiboot_ctrl_fsm/TASK_STATE.md
?? ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260720_021049_multiboot_board_verify_guidance_report.md
?? prompts/codex/009_push_multiboot_board_verify.md
?? scripts/open_latest_wbd.sh
```

## 20. 最终 Git Diff Stat

最终 `git diff --stat`：

```text
 ai_workflow/HANDOFF_CURRENT.md                     | 24 +++++++++++-----------
 ai_workflow/TASK_INDEX.md                          |  3 ++-
 .../20260717_multiboot_ctrl_fsm/TASK_STATE.md      | 14 ++++++++-----
 3 files changed, 23 insertions(+), 18 deletions(-)
```

普通 `git diff --stat` 不包含未跟踪的新 report、009 prompt 和新增脚本；三者已由最终 `git status` 标注。`git diff --check` 最终 PASS。
