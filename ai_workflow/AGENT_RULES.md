# Agent 工作规则

## 1. 工程定位

本工程是 FPGA/Vivado/RTL/板卡调试工程，涉及：

- Linux 环境下 Vivado 批处理编译
- Windows 环境下板卡调试、Python UDP 工具运行、Vivado Hardware Manager / ILA 观测
- RTL 修改
- Tcl / ILA 调试脚本
- Python 辅助工具
- 报告与日志归档
- Codex / Claude Code 接力工作

## 2. 每个 agent 开始前必须读取

默认启动读取包必须保持轻量，避免多份摘要互相复制后产生滚动漂移。

每轮默认只读：

- `ai_workflow/HANDOFF_CURRENT.md`
- 当前任务目录下的 `TASK_STATE.md`
- 本轮 prompt 明确指定的 report / 文件

按需读取：

- `ai_workflow/AGENT_RULES.md`：流程规则不清、需要修改 workflow、或本轮 prompt 要求时。
- `ai_workflow/TASK_INDEX.md`：需要选择 / 切换任务、核对任务总表或跨任务硬事实/红线时（原 `PROJECT_STATE.md` 已并入本文件）。
- 当前任务目录下的 `TASK.md`：任务目标或相关源码范围不清时。
- 当前任务目录下的 `ACCEPTANCE.md`：验收口径不清或验收标准要变更时。
- 历史 reports：只读本轮 prompt、`HANDOFF_CURRENT.md` 或 `TASK_STATE.md` 明确引用的 report；不得默认通读全量历史。

`最新 report` 仍按本文件 §3e 发现，但默认只记录路径和漂移情况；是否读取内容由本轮任务需要决定。

## 3. 每轮开始前必须记录

必须执行并记录：

```bash
git branch --show-current
git status --short
git diff --stat
```

如果本轮 prompt 提供了更窄的 `COMMAND_ALLOW` / `COMMAND_DENY`，则以本轮 prompt 为准。因命令边界收窄而未执行的默认检查，必须在 report 的边界自检中说明。

## 3a. 每轮 prompt 语义类型

后续每轮 prompt 应尽量使用 v2 结构，只保留本轮差量信息。agent 必须按语义强度处理输入：

- `FACT`：人类确认的事实、日志、现象、路径、报告链接。agent 必须尊重并可复核，不得无证据否定。
- `GOAL`：本轮目标。agent 必须服务目标，可以自主选择实现路径，但不得替换目标。
- `BOUNDARY`：硬边界。agent 不得越界；如完成目标需要越界，只能写入待授权事项。
- `ALLOWLIST`：本轮允许修改或新增的文件 / 路径范围。未列入者默认只读。
- `WRITE_ALLOW`：`ALLOWLIST` 的同义字段。两者同时出现时按并集理解允许写入范围，但 hard-readonly 和硬边界仍优先。
- `RUN_POLICY`：本轮运行权限，包含运行等级、自然语言权限说明、允许命令和禁止命令。它与 `COMMAND_ALLOW` / `COMMAND_DENY` 共同定义命令边界。
- `COMMAND_ALLOW` / `COMMAND_DENY`：`RUN_POLICY` 内或独立出现的具体命令允许 / 禁止清单。禁止项优先于允许项；自然语言说明与清单冲突时取更严格解释。
- `OVERRIDE_BOUNDARY`：本轮相对默认规则的差量边界，分为 `EXTRA_ALLOW`、`EXTRA_DENY`、`EXTRA_READONLY`。
- `PREFERENCE`：人工偏好。agent 应优先考虑；如偏离，必须在 report 中说明证据和理由。
- `HYPOTHESIS`：人工假设。agent 必须自行验证，可以推翻，不得直接当事实或命令。
- `DELIVERABLE`：必须交付的产物。未完成时必须进入 PARTIAL 交接协议。
- `ACCEPTANCE` / `ROLLBACK`：本轮验收口径和回滚说明要求。agent 必须逐项回应。

## 3b. 默认权限模型与 hard-readonly

三段式运行权限：

- `R0`：只读检查。只能运行只读检查命令；不得修改既有工程 / workflow 文件。若本轮明确要求新增 report，可仅在 `WRITE_ALLOW` / `ALLOWLIST` 允许的新 report 路径内写入报告。
- `R1`：可运行验证但不修改工程。可运行 `RUN_POLICY` 授权的验证命令；不得修改工程逻辑、脚本、约束或状态入口文件，除非本轮明确允许 report / handoff / state 类文件写入。
- `R2`：可运行且可修改 `WRITE_ALLOW` / `ALLOWLIST` 内文件。仍不得越过 hard-readonly、硬边界、`COMMAND_DENY` 或本轮额外只读范围。

自然语言运行权限说明有效。例如“只读检查”“可运行验证但不修改工程”“禁止 Vivado / 禁止上板 / 禁止发送 UDP”必须被转换为实际命令和动作边界；若无法确定某条命令是否被允许，默认不执行并写入 report。

R0 时间戳例外：只读 / report-only 轮默认允许执行 `date +%Y%m%d_%H%M%S` 生成 report 时间戳，除非本轮 prompt 明确禁止 `date` 或直接提供 TS。若采用 prompt 提供的 TS 或无法运行 `date`，必须在 report 中说明。

默认权限模型：

- 未在本轮 `WRITE_ALLOW` / `ALLOWLIST` 中列出的文件，默认只读。
- 未在本轮 `RUN_POLICY` / `COMMAND_ALLOW` 中列出的命令，默认禁止执行；若 prompt 未定义命令边界，则执行本文件要求的启动和审计命令。
- 未明确授权的硬件动作、Python 硬件测试、Vivado build/synth/impl/bitstream、read mode apply，默认禁止。
- `WRITE_ALLOW` / `ALLOWLIST` 不能覆盖永久硬边界。
- `WRITE_ALLOW` / `ALLOWLIST` 不能覆盖 hard-readonly 文件规则。

默认 hard-readonly 文件：

- `ai_workflow/AGENT_RULES.md`
- `ai_workflow/tasks/**/ACCEPTANCE.md`

如需修改 hard-readonly 文件，必须在本轮 `OVERRIDE_BOUNDARY` / `EXTRA_ALLOW` 中显式说明修改对象、理由、范围和审计要求；否则即使出现在 `WRITE_ALLOW` / `ALLOWLIST` 中也必须视为只读。

## 3c. Agent 自主性与修改规模

在不突破系统规则、本轮边界、hard-readonly、allowlist 和禁止事项的前提下，agent 可以自主：

- 查找相关文件、阅读历史 report、验证或推翻人工假设。
- 选择更低风险实现路径。
- 做最小必要修改。
- 同步必要状态文件。
- 生成 report。
- 提出下一轮最小验证方案。

轻量自主修改的默认边界：

- 非 report / handoff / state 文件的实际修改文件数不超过 3 个。
- 非文档类代码或脚本净变更不超过 80 行。
- 不改变默认行为。
- 不影响 legacy path。
- 不引入新的 build / test / hardware 流程。
- 不扩大本轮目标。

超过上述任一条件时，必须在 report 中标记为“扩大修改”，说明必要性、涉及文件、风险、人工 review 重点和是否建议拆到下一轮授权。若扩大修改会触碰硬边界、hard-readonly、未授权文件或高风险硬件路径，必须停止并写入待授权事项。

## 3d. 可审计要求

凡是超出人工明确任务、但仍在权限内的额外动作，必须在 report 中单独说明：

- 做了什么。
- 为什么做。
- 收益是什么。
- 风险是什么。
- 是否影响默认行为。
- 是否影响 legacy path。
- 如何通过 git diff 审查。
- 是否建议人工重点 review。

## 3e. latest report 发现与收尾核验

每轮开始时必须发现当前任务 `reports/` 目录下按时间戳文件名排序的最新 report 路径，并与 `TASK_INDEX.md` 的“最新报告”字段、本轮 prompt 指定的参考报告进行比对：

- 若 `TASK_INDEX.md` 指针滞后，以 `reports/` 目录实际最新文件和本轮 prompt 指定文件共同作为依据，并在 report 中记录漂移；是否读取 report 内容按 §2 的按需规则执行。
- 若 prompt 指定的 report 不存在，必须在 report 中记录缺失路径，不得臆造内容。
- 若最新 report 是未跟踪文件，应通过 `git status --short` 标注 `??` 状态，不得清理或忽略。

每轮结束前必须尽量执行并写入 report：

```bash
git status --short
git diff --stat
```

若本轮 `RUN_POLICY` 禁止这些命令，必须在 report 中说明未执行原因和风险。新增未跟踪 report 不会出现在普通 `git diff --stat` 中，必须同时依赖 `git status --short` 核验。

## 4. 每轮结束后更新矩阵

默认只更新：

- 当前任务 `reports/` 下的时间戳报告。
- `ai_workflow/HANDOFF_CURRENT.md`（仅在下一轮第一屏需要变化时）。

只有对应事实变化时才更新：

- 当前任务 `TASK_STATE.md`：gate 变化、长期事实变化、下一步唯一动作变化、证据边界变化。
- `ai_workflow/TASK_INDEX.md`：任务状态、当前阶段、下一步、最新 report 指针或跨任务硬事实/红线变化（已吸收原 `PROJECT_STATE.md`；任务级 `HANDOFF.md` 已废除）。
- 当前任务 `TASK.md`：任务目标、相关源码 / 工具范围等稳定定义变化。
- 当前任务 `ACCEPTANCE.md`：验收标准或验收口径变化。

禁止为了“同步”把同一段事实复制到多个入口文件。摘要文件只能保留短口径和指针；长期事实以 `TASK_STATE.md` 为准，证据细节进 report。

例外：

- 若本轮为只读 / report-only，或 `WRITE_ALLOW` / `ALLOWLIST` 未允许修改上述文件，不得为了满足默认更新而越界修改。
- 若本轮目标本身就是 report-only，未更新状态入口不构成 PARTIAL；必须在 report 中说明哪些状态文件未同步、原因和后续同步建议。
- 若本轮 `DELIVERABLE` 要求状态同步但写权限禁止同步，则必须按 PARTIAL 交接协议记录冲突，不得擅自扩大写入范围。

## 5. 每轮 report 必填结构

每轮 report 必须包含：

- AI 模型类型。
- 本轮任务。
- git baseline：branch、status、diff stat、recent log。
- 输入事实摘要。
- latest report 发现结果。
- 边界自检。
- 修改摘要。
- 实际改动文件。
- 额外自主修改说明。
- 验证情况。
- 未执行事项。
- 风险与注意事项。
- 下一轮建议。
- 待授权事项。
- FPGA 调试 yes/no 状态。
- 最终 `git status --short`。
- 最终 `git diff --stat`。

边界自检必须包含：

- 本轮我理解的 `WRITE_ALLOW` / `ALLOWLIST`。
- 本轮我理解的 `RUN_POLICY` / `COMMAND_ALLOW` / `COMMAND_DENY`。
- 本轮我理解的 `OVERRIDE_BOUNDARY`。
- 实际修改了哪些文件。
- 实际运行了哪些命令。
- 是否触碰禁止项。
- 是否修改 hard-readonly 文件。
- 是否存在额外自主修改。
- 是否越界：yes/no。

FPGA 调试 yes/no 状态必须说明：

- 是否修改 RTL
- 是否修改 XDC
- 是否修改 Tcl
- 是否修改 Python
- 是否运行 Vivado
- 是否生成 bitstream
- 是否上板
- 是否发送真实 UDP 包
- 是否修改 MIG/IP

如任一项为 yes，必须说明做了什么、为什么被授权、证据位置和风险。

## 6. 禁止行为

- 不允许自动扩大修改范围
- 不允许自动 git commit
- 不允许 git reset
- 不允许 git clean
- 不允许删除用户文件
- 不允许清理已有脏改动

## 7. 工程专有概念边界（模板占位，按新工程替换）

<在此定义本工程"不得混称"的概念对，示例格式：
仿真后端验证 ≠ 真实硬件后端验证；回环 PASS ≠ 数据值正确。
若暂无可删除本节并顺延编号。>

## 8. 脏工作区处理原则

如果工作区已有与本轮任务无关的脏改动：

- 只记录状态。
- 不清理。
- 不回滚。
- 不为了通过检查去修改无关 RTL/Tcl/XDC/Python。
- 如果脏改动影响任务判断，应在报告和 handoff 中明确标注风险。

## 中途失败 / PARTIAL 交接协议

如果 agent 无法完整完成本轮任务，必须执行部分交接：

- 不得回滚已完成的授权内修改，除非回滚本身被授权且是安全必要动作。
- 必须生成或更新 report，并在头部标注 `PARTIAL`。
- 必须更新 `TASK_STATE.md` 或 `HANDOFF_CURRENT.md` 中至少一个接力文件。
- 必须说明已完成什么、未完成什么、停止原因、当前 workspace 是否有修改、已修改文件列表、下一轮应从哪里继续、是否需要额外授权。
- 若因 dirty workspace、权限冲突或硬边界冲突停止，必须明确列出冲突点。

只读 / report-only 冲突例外：若本轮 `WRITE_ALLOW` / `ALLOWLIST` 明确禁止修改 `TASK_STATE.md` 和 `HANDOFF_CURRENT.md`，则不得违反边界；必须把完整 PARTIAL 交接信息写入本轮 report，并说明状态入口待后续授权同步。

## 单一事实来源原则

当前任务状态以该任务目录下的 TASK_STATE.md 为唯一事实来源。
HANDOFF_CURRENT.md、TASK_INDEX.md、TASK.md、ACCEPTANCE.md 和 report 可以写摘要或验收口径，但不得与 TASK_STATE.md 冲突。
同一事实只允许有一个主存放位置；其它文件只能短摘要引用或提供稳定定义，不得复制完整事实链。
如果摘要和 TASK_STATE.md 冲突，应以 TASK_STATE.md 为准，优先修摘要，不改事实源，并在 report 中记录本轮修正。

## 提交策略

agent 不得自动执行 git commit、git stash、git reset、git clean。
每轮 agent 完成后，由人类工程师审查 report、git status、git diff 后决定是否提交。
建议每个工程阶段开始前由人类建立 checkpoint commit。

## 时间戳生成规则

所有报告、日志、handoff 时间戳应由命令生成：

TS=$(date +%Y%m%d_%H%M%S)

不得手工伪造时间戳。跨平台时 Windows 可使用 PowerShell 等效时间戳命令。

R0 / report-only 轮若需要报告文件名，`date +%Y%m%d_%H%M%S` 属默认允许的只读时间戳命令；若 prompt 显式禁止或提供固定 TS，以 prompt 为准并记录原因。

## 规则优先级

当多个工作流文件或本轮 prompt 出现冲突时，按以下优先级执行：

```text
P0：系统/平台安全规则，不可覆盖
P1：本轮 Agent Task Prompt / 人工输入
P2：TASK_STATE.md
P3：ACCEPTANCE.md
P4：AGENT_RULES.md
P5：HANDOFF_CURRENT.md / TASK_INDEX.md
```

解释：

```text
1. 本轮 Agent Task Prompt 是当前任务最高优先级事实来源，用于定义本轮目标、权限、允许修改文件、允许命令、验收标准。
2. TASK_STATE.md 是任务长期状态来源；如果与本轮 prompt 冲突，以本轮 prompt 为准，并在 report 中记录差异。
3. ACCEPTANCE.md 定义任务验收边界；如本轮 prompt 明确调整验收范围，以本轮 prompt 为准。
4. AGENT_RULES.md 定义默认工作流规则；本轮 prompt 可收窄或扩大权限，但必须显式写明。
5. HANDOFF_CURRENT / TASK_INDEX 用于背景和接力，不应覆盖本轮 prompt。
```

## 冲突处理

如果发现规则冲突，必须按以下方式处理：

```text
1. 先停止扩大修改范围。
2. 在 report 中列出冲突项。
3. 标明采用了哪个优先级的规则。
4. 如涉及不可覆盖红线，必须等待人工确认。
```
