# 报告：Multiboot 抽象状态机 XSim 功能仿真闭环

- AI 模型类型：Codex / GPT-5 coding agent
- 时间戳：20260717_021312
- 本轮任务：读取并执行 `prompts/codex/002_build_corresponding_linux_xsim_functional_simulation_closed_loop.md`

## git baseline

- branch：`dev`
- recent log：`e9a8047 Xsim冒烟测试-可观察vivado仿真波形`
- 开工 `git status --short`：`?? prompts/codex/002_build_corresponding_linux_xsim_functional_simulation_closed_loop.md`
- 开工 `git diff --stat`：无输出

## 输入事实摘要

- 前置最小 XSim smoke 测试已真实通过，已验证 `Shell -> Tcl -> xvlog -> xelab -> xsim -> Testbench -> RESULT=PASS`。
- 本轮目标是实现抽象 Multiboot 状态机，并建立对应 Linux XSim 功能级仿真闭环。
- 本轮只验证抽象命令序列和控制行为，不验证真实 FPGA 重配置。

## latest report 发现结果

- 当前 handoff 开工时指向 `reports/20260717_xsim_smoke_test_20260717_011642.md`，但该路径不在当前仓库中。
- 前置 smoke 任务目录中最新可见 report 为 `ai_workflow/tasks/20260717_xsim_smoke_test/reports/20260717_xsim_smoke_test_20260717_010037.md`。
- 本轮按新报告规则写入任务目录：`ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260717_021312_multiboot_ctrl_fsm_xsim_report.md`。

## 边界自检

- WRITE_ALLOW / ALLOWLIST：
  - `rtl/hdl/user/multiboot/**`
  - `sim/tb/tb_multiboot_ctrl.v`、`sim/tb/**multiboot**`
  - `sim/xsim/**`、`sim/wave/**`
  - `tcl/sim/**`
  - `scripts/vivado2018_common.sh`、`scripts/open_latest_gui.sh`、`scripts/**multiboot**`
  - `ai_workflow/AGENT_RULES.md`、`ai_workflow/HANDOFF_CURRENT.md`、`ai_workflow/TASK_INDEX.md`、`ai_workflow/templates/**`
  - `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/**`
  - `_artifacts/latest`
- RUN_POLICY：R2，可修改并可运行 Multiboot 状态机 XSim 功能级仿真；禁止综合、实现、bitstream、Flash 写入、上板、真实 UDP。
- OVERRIDE_BOUNDARY：prompt 未单独给出，但 P1 prompt 明确把 `ai_workflow/AGENT_RULES.md` 放入 WRITE_ALLOW，且 ACCEPTANCE 要求长期落地报告规则；本轮采用 P1，最小修改 `AGENT_RULES.md`。
- 实际修改 hard-readonly：yes，`ai_workflow/AGENT_RULES.md`。原因如上，修改范围仅为默认报告路径规则。
- 是否触碰禁止项：no。
- 是否越界：no。

## 实际修改文件

- `rtl/hdl/user/multiboot/multiboot_ctrl.v`
- `sim/tb/tb_multiboot_ctrl.v`
- `tcl/sim/xsim_multiboot_ctrl.tcl`
- `scripts/vivado2018_common.sh`
- `ai_workflow/AGENT_RULES.md`
- `ai_workflow/templates/report_template.md`
- `ai_workflow/HANDOFF_CURRENT.md`
- `ai_workflow/TASK_INDEX.md`
- `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/TASK.md`
- `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/TASK_STATE.md`
- `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/ACCEPTANCE.md`
- `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260717_021312_multiboot_ctrl_fsm_xsim_report.md`

## 状态机外部行为说明

- 请求接口：`req_valid_i` / `req_ready_o` / `req_addr_i`。
- 抽象发送接口：`cmd_valid_o` / `cmd_ready_i` / `cmd_data_o` / `cmd_last_o`。
- 状态观测：`idle_o`、`busy_o`、`done_o`、`err_o`、`state_o`、`cmd_index_o`、`target_addr_o`。
- 接受请求后锁存目标地址，并发送 8 个抽象命令字：
  - `FFFFFFFF`
  - `AA995566`
  - `20000000`
  - `30020001`
  - `<latched target address>`
  - `30008001`
  - `0000000F`
  - `20000000`
- `cmd_ready_i=0` 时，当前 `cmd_data_o`、`cmd_last_o` 和 index 保持稳定。
- 执行期间 `req_ready_o=0`，新请求不被接受。
- 复位使状态机回到 idle，并清空 latched target。
- 本轮未实例化 ICAPE2/ICAPE3 或其它器件专用原语。

## Testbench 测试项

- 连续 ready：完整发送预期序列并正常 done。
- 间歇 backpressure：验证数据不丢失、不重复、不乱序，且 ready 低时保持稳定。
- busy 期间新请求：验证当前流程不被覆盖或重新启动。
- 执行中 reset：验证发送过程被终止，状态机回到 idle，随后可重新完成新请求。
- 自动检查命令内容、数量、顺序、`cmd_last_o`、latched target 和状态输出。

## Shell/Tcl/XSim 调用链

```text
./scripts/vivado2018_common.sh xsim-multiboot-ctrl
  -> vivado -mode batch -source tcl/sim/xsim_multiboot_ctrl.tcl
  -> xvlog rtl/hdl/user/multiboot/multiboot_ctrl.v sim/tb/tb_multiboot_ctrl.v
  -> xelab xil_defaultlib.tb_multiboot_ctrl
  -> xsim multiboot_ctrl_snapshot
  -> tb_multiboot_ctrl prints RESULT=PASS/FAIL
```

## 实际运行命令

```bash
bash -n scripts/vivado2018_common.sh
git diff --check
./scripts/vivado2018_common.sh xsim-multiboot-ctrl
sed -n '1,220p' _runs/latest/summary.txt
sed -n '1,220p' _runs/latest/status.txt
rg -n "RESULT=|ERROR|CRITICAL WARNING|CRITICAL|WARNING|Built simulation snapshot|TEST_CASE" _runs/latest/logs/multiboot_ctrl_xvlog.log _runs/latest/logs/multiboot_ctrl_xelab.log _runs/latest/logs/multiboot_ctrl_xsim.log
find _artifacts/common_vivado/20260717_021704_xsim-multiboot-ctrl -maxdepth 1 -type f -printf '%p %s bytes\n'
readlink _runs/latest && readlink _artifacts/latest
```

## 首次运行结果

- 首次运行即通过。
- run id：`20260717_021704_xsim-multiboot-ctrl`
- `summary.txt`：`exit_status: 0`，`result: SUCCESS`
- `status.txt`：`exit_status=0`，`result=SUCCESS`，`artifact_latest_updated=1`，`artifact_latest_reason=success_complete`

## 修复过程

- XSim 首次运行未暴露 RTL/TB/Tcl 失败，因此没有运行后修复。
- 运行前完成的实现包括 RTL、TB、Tcl、Shell 入口和 `_artifacts/latest` 成功更新逻辑。

## 最终运行结果

- 最终运行就是首次运行：`20260717_021704_xsim-multiboot-ctrl`
- 结果：PASS
- `xsim` 日志记录：
  - `TEST_CASE: continuous ready`
  - `TEST_CASE: intermittent ready`
  - `TEST_CASE: busy request ignored`
  - `TEST_CASE: reset mid sequence`
  - `RESULT=PASS`

## RESULT=PASS/FAIL 证据

```text
_runs/latest/logs/multiboot_ctrl_xsim.log:24:RESULT=PASS
```

本轮可以声称：抽象 Multiboot 状态机功能级 XSim 仿真 PASS。

## WDB 路径和文件大小

```text
_artifacts/common_vivado/20260717_021704_xsim-multiboot-ctrl/multiboot_ctrl.wdb 29894 bytes
```

## latest 链接

- `_runs/latest` 指向：`common_vivado/20260717_021704_xsim-multiboot-ctrl`
- `_artifacts/latest` 指向：`common_vivado/20260717_021704_xsim-multiboot-ctrl`
- 两者指向同一轮运行：yes
- `_artifacts/latest` 是否在本轮更新：yes
- 更新条件：Shell/Tcl 成功、XSim 编译和 elaboration 成功、TB 输出 `RESULT=PASS`、WDB 存在、artifact 目录存在。

## 报告规则落地位置

- `ai_workflow/AGENT_RULES.md`：新增默认报告位置和文件命名规则。
- `ai_workflow/templates/report_template.md`：同步模板中的默认报告路径说明。

## 额外自主修改说明

- 新增 `_artifacts/latest` 更新逻辑只绑定 `xsim-multiboot-ctrl`，避免改变 synth/impl/bit/full 语义。
- 更新 `report_template.md` 是为了避免模板与 `AGENT_RULES.md` 的长期规则冲突。
- 将 `20260717_xsim_smoke_test` 在 `TASK_INDEX.md` 标为 DONE，并新增当前 ACTIVE 任务，避免多个任务都显示 ACTIVE。

## 未执行事项

- 未运行综合。
- 未运行实现。
- 未生成 bitstream。
- 未写 Flash。
- 未上板。
- 未发送真实 UDP 数据。
- 未实例化或接入 ICAPE2/ICAPE3。
- 未确定正式 Flash 地址布局。
- 未生成 Golden/Application 双镜像。

## 风险与注意事项

- 本轮 PASS 只覆盖抽象状态机、抽象命令流和 testbench 约定序列。
- 命令字采用抽象发送接口输出，尚未证明真实 ICAP 时序、位序、配置寄存器语义或板级重配置行为正确。
- `AGENT_RULES.md` 是默认 hard-readonly；本轮依据 P1 prompt 的明确 WRITE_ALLOW 和 ACCEPTANCE 最小修改，需人工重点 review。
- `sim/tb/tb_multiboot_ctrl.v` 和 `rtl/hdl/user/multiboot/multiboot_ctrl.v` 开工时为空文件，本轮为实质新增内容。

## 下一轮建议

- 人工审查本任务 diff/report 后决定是否提交。
- 若继续推进，建议单独定义真实 ICAP wrapper 或更高层 Multiboot 请求来源的边界、仿真模型和验收口径。

## 待授权事项

- 接入 ICAPE2/ICAPE3、Flash 布局、Golden/Application 镜像或上板 Multiboot 需要新一轮明确授权。

## FPGA 调试 yes/no 状态

- 是否修改 RTL：yes，新增/完善 `multiboot_ctrl` 抽象状态机。
- 是否修改 XDC：no。
- 是否修改 Tcl：yes，新增 `tcl/sim/xsim_multiboot_ctrl.tcl`。
- 是否修改 Python：no。
- 是否运行 Vivado：yes，用户 prompt 授权运行 XSim 功能级仿真，命令为 `./scripts/vivado2018_common.sh xsim-multiboot-ctrl`。
- 是否生成 bitstream：no。
- 是否上板：no。
- 是否发送真实 UDP 包：no。
- 是否修改 MIG/IP：no。
- 是否执行 git commit/reset/clean/stash：no。

## 最终 git status --short

```text
 M ai_workflow/AGENT_RULES.md
 M ai_workflow/HANDOFF_CURRENT.md
 M ai_workflow/TASK_INDEX.md
 M ai_workflow/templates/report_template.md
 M rtl/hdl/user/multiboot/multiboot_ctrl.v
 M scripts/vivado2018_common.sh
 M sim/tb/tb_multiboot_ctrl.v
?? ai_workflow/tasks/20260717_multiboot_ctrl_fsm/
?? prompts/codex/002_build_corresponding_linux_xsim_functional_simulation_closed_loop.md
?? tcl/sim/xsim_multiboot_ctrl.tcl
```

## 最终 git diff --stat

普通 `git diff --stat` 不显示未跟踪文件；未跟踪文件见 `git status --short`。

```text
 ai_workflow/AGENT_RULES.md               |   7 +
 ai_workflow/HANDOFF_CURRENT.md           |  19 +-
 ai_workflow/TASK_INDEX.md                |   7 +-
 ai_workflow/templates/report_template.md |   5 +-
 rtl/hdl/user/multiboot/multiboot_ctrl.v  | 214 +++++++++++++++++
 scripts/vivado2018_common.sh             |  37 +++
 sim/tb/tb_multiboot_ctrl.v               | 392 +++++++++++++++++++++++++++++++
 7 files changed, 668 insertions(+), 13 deletions(-)
```
