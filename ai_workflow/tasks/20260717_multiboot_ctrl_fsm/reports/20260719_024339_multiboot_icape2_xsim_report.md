# 报告：Multiboot ICAPE2 链路与 UNISIM XSim 验证

- AI 模型类型：Codex / GPT-5 coding agent
- 时间戳：20260719_024339
- 本轮任务：读取并执行 `prompts/codex/003_advance_icap_logic_implementation_simulation_and_document_description.md`
- 最终结论：`RESULT=PASS`，仅限 ICAPE2 UNISIM 接口仿真边界

## git baseline

- branch：`dev`
- baseline：`076720e 增加最小multiboot逻辑实现`
- recent log：`076720e`、`e9a8047`、`f8eb58d`
- 开工 `git status --short`：`M prompts/codex/003_advance_icap_logic_implementation_simulation_and_document_description.md`
- 开工 `git diff --stat`：仅上述用户 prompt，30 行差量；本轮未修改该文件

## 输入事实摘要

- 前置抽象 controller 和 XSim 功能仿真已 PASS，但没有接入 ICAP 原语。
- 本轮授权目标为 Xilinx 7 Series / Zynq-7000 PL 侧 `ICAPE2`，允许修改 Verilog/Tcl/Shell 和 workflow 状态，并允许真实运行 Vivado 2018.3 xvlog/xelab/xsim。
- 禁止综合、实现、bitstream、MCS/BIN、Flash 写入、上板和真实重配置。

## latest report 发现结果

- 开工时当前任务 `reports/` 实际最新文件为 `20260717_021312_multiboot_ctrl_fsm_xsim_report.md`。
- prompt 指定的前置报告存在且与实际 latest 一致。
- `TASK_INDEX.md` 没有独立“最新报告”字段；任务行指向 `TASK_STATE.md`，未发现相互冲突。
- 本轮新报告为 `20260719_024339_multiboot_icape2_xsim_report.md`。

## 边界自检

- WRITE_ALLOW：新增/修改 `.v`、`.sh`、`.tcl`，更新 multiboot 任务状态/handoff/index，新增本报告。
- RUN_POLICY：R2；允许 Vivado 2018.3 batch、xvlog、xelab、xsim、UNISIM 和只读 git/Shell 检查。
- COMMAND_DENY / HARD_BOUNDARY：不运行 synth/impl/bitstream/MCS/BIN，不写 Flash，不上板，不触发真实重配置，不执行 git 写操作。
- OVERRIDE_BOUNDARY：无；`ai_workflow/AGENT_RULES.md` 与 `ACCEPTANCE.md` 保持只读。
- 实际工程修改：1 个新增 RTL wrapper、1 个 TB、1 个 Tcl，共 3 个非状态/报告文件。
- 实际状态修改：`TASK_STATE.md`、`HANDOFF_CURRENT.md`、`TASK_INDEX.md`，另新增本报告。
- 是否触碰禁止项：no。
- 是否修改 hard-readonly：no。
- 是否存在额外自主修改：no。
- 是否越界：no。

## 官方资料与本地工具依据

### AMD/Xilinx 官方资料

- [UG953 ICAPE2](https://docs.amd.com/r/2022.2-English/ug953-vivado-7series-libraries/ICAPE2)：ICAPE2 是 7 Series 配置访问原语；端口为 `CLK`、active-low `CSIB`、`I[31:0]`、`O[31:0]`、`RDWRB`，支持 `ICAP_WIDTH="X32"`。
- [UG470 v1.17](https://docs.amd.com/api/khub/documents/FOs3lXmlcWxBhTIFxVKyGA/content)：Parallel Bus Bit Order 说明 ICAPE2 的 x32 数据需要每个 byte 内 bit-swap；同步字 `AA995566` 在 ICAPE2 引脚侧为 `5599AA66`。
- UG470 Chapter 7 Table 7-1 给出的 IPROG through ICAPE2 序列是 dummy、sync、NOOP、写 WBSTAR、地址、写 CMD、IPROG、NOOP，与本 controller 的 8 words 一致。

### Vivado 2018.3 本地依据

- 原语模型：`/opt/Xilinx/Vivado/2018.3/data/verilog/src/unisims/ICAPE2.v`，定义 `ICAPE2`、默认 X32，并实例化 `SIM_CONFIGE2`。
- 本地 2018.3 Verilog 模板：`data/parts/xilinx/templates/vivado/verilog.xml`，包含 Artix-7 `ICAPE2` X32 实例模板。
- 器件库：`data/parts/xilinx/virtex7/devint/virtex7.lib` 与 `data/parts/xilinx/zynq/devint/zynq.lib` 均包含 `cell(ICAPE2)`。
- 最终 run 记录的 part 为 `xc7vx690tffg1927-2`（Virtex-7）；本轮命令行 XSim 不创建 part-specific project，但本地器件库与 UG953 均支持目标架构的 ICAPE2。

## 实现说明

### 链路边界

```text
req_valid/req_addr
    -> multiboot_ctrl
    -> cmd_valid/cmd_ready/cmd_data
    -> multiboot_icape2_wrapper
    -> CSIB/RDWRB/I[31:0]
    -> unisims_ver.ICAPE2
    -> unisims_ver.SIM_CONFIGE2
```

- `multiboot_ctrl.v` 未修改，继续保持器件无关。
- wrapper 只做 write-only ICAPE2 接入、enable/backpressure、reset 屏蔽和逐 byte bit-reversal。
- `cmd_ready_o = icap_enable_i && !reset`；ICAPE2 无 ready 输出，`icap_enable_i` 由端口 owner 用于初始化等待、仲裁或暂停。
- 成功 command fire 时 `CSIB=0`、`RDWRB=0`；无 fire 或 reset 时 `CSIB=1`。
- `SIM_CFG_FILE_NAME="NONE"`，本轮不提供或生成 RBT/bitstream。

### 命令与实际 ICAPE2 数据

最终日志逐拍记录如下；physical 是 wrapper 实际送到 `ICAPE2.I[31:0]` 的值：

| index | 逻辑配置字 | 含义 | ICAPE2 physical |
|---:|---:|---|---:|
| 0 | `FFFFFFFF` | Dummy | `FFFFFFFF` |
| 1 | `AA995566` | Sync | `5599AA66` |
| 2 | `20000000` | Type-1 NOOP | `04000000` |
| 3 | `30020001` | Write 1 word to WBSTAR | `0C400080` |
| 4 | `00200000` | WBSTAR payload | `00040000` |
| 5 | `30008001` | Write 1 word to CMD | `0C000180` |
| 6 | `0000000F` | IPROG | `000000F0` |
| 7 | `20000000` | Type-1 NOOP | `04000000` |

UNISIM 在反向解析 physical 数据后实际观测到 `WBSTAR=0x00200000`，并产生 IPROG pulse。

## 地址语义边界

- 当前接口将 `req_addr_i` 原样作为 WBSTAR register payload，不声称它已经是任一具体 Flash 配置模式的正确 byte address 编码。
- UG470 对 Master SPI 说明：物理地址的高 24 位写入 `WBSTAR[23:0]`；因此若上层传入 byte address，通常需要按配置模式转换，不能把本轮示例 payload 直接当作已验证 Flash 布局。
- BPI/SPI、24/32-bit addressing、dummy bytes、镜像对齐和 fallback 均未在本轮确定。

## Testbench 覆盖

- 等待并层次观测 Vivado 2018.3 UNISIM `ICAPE2.icap_idone`，避免初始化前发送。
- 检查 8 words 的内容、数量、顺序、index 和 last。
- 每一 fire 检查 `CSIB=0`、`RDWRB=0` 和实际 `I[31:0]` bit-reversal。
- `icap_enable_i=0` 三拍期间检查 ready 低、controller 数据/last 保持、`CSIB=1`、无丢失或重复。
- busy 期间注入新 request，检查 ready 低且活动 target 不被覆盖。
- 第一 word 后断言 reset，检查流立即终止、controller 回 idle、target 清零、ICAP deselect。
- 完整序列后检查 UNISIM 内部 WBSTAR 值与 IPROG pulse。

## Tcl / XSim 调用链

```text
./scripts/vivado2018_common.sh xsim-multiboot-ctrl
  -> Vivado 2018.3 batch
  -> xvlog controller + wrapper + TB + Vivado glbl.v, -L unisims_ver
  -> xelab tb + glbl, -L unisims_ver
  -> unisims_ver.ICAPE2 + unisims_ver.SIM_CONFIGE2
  -> xsim -> RESULT=PASS + WDB
```

独立命令行 XSim 必须编译 Vivado 自带 `data/verilog/src/glbl.v` 并把 `xil_defaultlib.glbl` 作为 elaboration top；否则 `SIM_CONFIGE2` 的全局 GSR/GTS 引用无法解析。

## 实际运行命令

```bash
git branch --show-current
git status --short
git diff --stat
git log -5 --oneline
bash -n scripts/vivado2018_common.sh
git diff --check
./scripts/vivado2018_common.sh xsim-multiboot-ctrl
rg -n "RESULT=|ICAP_WRITE|CHECK_PASS|ICAPE2|SIM_CONFIGE2" _runs/latest/logs/*
find -L _artifacts/latest -maxdepth 1 -type f -printf '%p %s bytes\n'
readlink _runs/latest
readlink _artifacts/latest
```

## 运行与修复过程

1. `20260719_024057_xsim-multiboot-ctrl`：xelab FAIL，`SIM_CONFIGE2` 找不到 `glbl`；修复 Tcl 编译并 elaboration Vivado 2018.3 官方 `glbl.v`。
2. `20260719_024140_xsim-multiboot-ctrl`：UNISIM elaboration 成功，TB `RESULT=FAIL fail_count=1`；定位为 reset 注入 task 额外等待一个 negedge，导致多发送一拍，修复 TB stimulus。
3. `20260719_024210_xsim-multiboot-ctrl`：`RESULT=PASS`；随后仅增加逐拍 logical/physical 文本证据。
4. 最终 `20260719_024313_xsim-multiboot-ctrl`：`RESULT=PASS`。

失败 run 均保留，`_artifacts/latest` 在失败时没有更新；最终成功 run 才更新 artifact latest。

## 最终验证证据

- `status.txt`：`exit_status=0`、`result=SUCCESS`、`artifact_latest_updated=1`、`artifact_latest_reason=success_complete`。
- `multiboot_ctrl_xelab.log`：编译 `unisims_ver.SIM_CONFIGE2`、`unisims_ver.ICAPE2`，并生成 snapshot。
- `multiboot_ctrl_xsim.log`：UNISIM 初始化 PASS、8 条 full-sequence `ICAP_WRITE`、WBSTAR PASS、IPROG PASS、`RESULT=PASS`。
- `git diff --check`：通过；唯一输出为用户 prompt 的 CRLF 提示，不是 whitespace error。
- `bash -n scripts/vivado2018_common.sh`：通过；Shell 文件本轮未修改。

## WDB 与打开方式

- 路径：`_artifacts/common_vivado/20260719_024313_xsim-multiboot-ctrl/multiboot_ctrl.wdb`
- 大小：44104 bytes
- `_artifacts/latest/multiboot_ctrl.wdb` 指向同一文件。
- 可在 Vivado 2018.3 Tcl Console 使用：`open_wave_database /data/work/fpga/multiboot/_artifacts/common_vivado/20260719_024313_xsim-multiboot-ctrl/multiboot_ctrl.wdb`
- 建议观察：`cmd_valid_w/cmd_ready_w/cmd_data_w/cmd_index_w`、`icap_enable_r`、`icap_csib_w/icap_rdwrb_w/icap_data_i_w`、`busy_w/done_w`、UNISIM `wbstar_reg[0]` 与 `iprog_b[0]`。

## 实际改动文件

- `rtl/hdl/user/multiboot/multiboot_icape2_wrapper.v`（新增）
- `sim/tb/tb_multiboot_ctrl.v`
- `tcl/sim/xsim_multiboot_ctrl.tcl`
- `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/TASK_STATE.md`
- `ai_workflow/HANDOFF_CURRENT.md`
- `ai_workflow/TASK_INDEX.md`
- `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260719_024339_multiboot_icape2_xsim_report.md`（新增）

## 扩大修改与额外自主修改说明

- 非状态/报告文件数为 3，未超过默认数量边界。
- TB 改造和新增 wrapper 的净代码量超过默认 80 行，属于“扩大修改”；这是覆盖真实 ICAPE2 原语、控制/位序、UNISIM 内部解码、reset/busy/backpressure 验收所必需。
- 人工 review 重点：wrapper 的逐 byte bit-reversal、active-low `CSIB`、write `RDWRB=0`、`icap_enable_i` 的系统集成来源，以及 TB 的层次化 UNISIM 观测仅用于仿真。
- 不改变已有抽象 controller，Shell 入口和 legacy build/synth/impl 路径未修改。
- 无目标外额外自主修改。

## 能证明与不能证明

可以证明：

- Vivado 2018.3 可以真实编译/elaborate controller、wrapper、TB、glbl、ICAPE2 和 SIM_CONFIGE2。
- 当前 8-word 逻辑序列经逐 byte bit-reversal 后，被 UNISIM 解码为目标 WBSTAR payload 与 IPROG。
- reset、busy request、enable backpressure 和连续发送节拍满足 TB 断言。

不能证明：

- 精确板卡器件、Flash 配置模式和 ICAP 最大时钟约束均正确。
- `req_addr_i` 与实际 Flash byte address/镜像布局的编码正确。
- 真实 bitstream、MCS/BIN、Flash 内容、fallback 或板上 Multiboot 成功。
- UNISIM 时序/行为等价于所有真实器件边界条件。

## 未执行事项

- 未运行综合、实现或 timing analysis。
- 未生成 bitstream、MCS、BIN 或 RBT。
- 未写 Flash、未上板、未启动 Hardware Manager、未触发真实 FPGA 重配置。
- 未修改 XDC、Python、MIG/IP、`multiboot_ctrl.v`、Shell、hard-readonly 文件。
- 未执行 git add/commit/push/reset/clean/stash。

## 风险与注意事项

- wrapper 依赖外部 `icap_enable_i` 在 ICAPE2 可用后才放行；当前没有硬件级 startup/ownership 逻辑。
- 100 MHz 测试时钟只用于功能仿真；未对具体 part 的 `FICAPCK` 或时序收敛做证明。
- 层次访问 `SIM_CONFIGE2_INST` 是 Vivado 2018.3 TB 证据手段，不应进入可综合逻辑。
- 用户 prompt 的既有脏改动保持不动。

## 下一轮建议

- 人工审查本轮 diff/report 后决定是否提交。
- 下一 gate 应先固定精确 part、SPI/BPI 模式、Flash address width、镜像 byte offset 与 WBSTAR 编码，再定义 bitstream/Flash/Hardware Manager 的独立授权和回滚方案。

## 待授权事项

- 综合/实现、ICAP 时钟约束和资源检查。
- bitstream、MCS/BIN、Flash 镜像布局与生成。
- Flash 写入、上板 Multiboot/fallback 和 Hardware Manager 观测。

## FPGA 调试 yes/no 状态

- 是否修改 RTL：yes，新增 ICAPE2 wrapper；用户 prompt 明确授权，证据为源码和最终 XSim 日志；风险为器件/地址模式尚未上板确认。
- 是否修改 XDC：no。
- 是否修改 Tcl：yes，加入 wrapper、`unisims_ver` 和官方 `glbl.v` 的 xvlog/xelab；证据为最终 xelab 日志。
- 是否修改 Python：no。
- 是否运行 Vivado：yes，运行 4 次授权的 `xsim-multiboot-ctrl`，最终 PASS。
- 是否生成 bitstream：no。
- 是否上板：no。
- 是否发送真实 UDP 包：no。
- 是否修改 MIG/IP：no。

## 最终 git status --short

```text
 M ai_workflow/HANDOFF_CURRENT.md
 M ai_workflow/TASK_INDEX.md
 M ai_workflow/tasks/20260717_multiboot_ctrl_fsm/TASK_STATE.md
 M prompts/codex/003_advance_icap_logic_implementation_simulation_and_document_description.md
 M sim/tb/tb_multiboot_ctrl.v
 M tcl/sim/xsim_multiboot_ctrl.tcl
?? ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260719_024339_multiboot_icape2_xsim_report.md
?? rtl/hdl/user/multiboot/multiboot_icape2_wrapper.v
```

其中 prompt 是开工前用户脏改动，本轮未触碰。

## 最终 git diff --stat

```text
 ai_workflow/HANDOFF_CURRENT.md                     |  25 +-
 ai_workflow/TASK_INDEX.md                          |   4 +-
 .../20260717_multiboot_ctrl_fsm/TASK_STATE.md      |  49 ++-
 ...entation_simulation_and_document_description.md |  30 +-
 sim/tb/tb_multiboot_ctrl.v                         | 456 ++++++++++++---------
 tcl/sim/xsim_multiboot_ctrl.tcl                    |  17 +-
 6 files changed, 317 insertions(+), 264 deletions(-)
```

普通 `git diff --stat` 不显示新增 wrapper 和本报告；完整文件集合必须结合上述 `git status --short` 审查。
