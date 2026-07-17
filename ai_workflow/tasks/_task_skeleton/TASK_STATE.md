# <slug> 任务状态（纯快照）

> 本文件是本任务状态的唯一事实来源（SSOT），**agent 专用**；硬上限 150 行。
> 禁止出现"本轮（…）"逐轮叙事；每轮更新方式 = 就地改写相应行 + 更新指针，不追加段落。
> 轮次历史 = 本目录 `reports/` + git log。任务定义见 `TASK.md`；验收见 `ACCEPTANCE.md`。
> 摘要/接力文件（HANDOFF_CURRENT / TASK_INDEX）与本文冲突时以本文为准，优先修摘要。

## 1. 当前状态

- ACTIVE。阶段：**S0 初始化完成（<TS>）**。
- 唯一下一步见 §6。

## 2. 关键事实（每条一行，证据 = report/commit 指针）

### 继承基线
- <每条一行 + 指针>

### 本任务新增事实
- （暂无；开工后在此逐行登记，就地改写不追加）

## 3. 阶段门（每 gate 一行：Planned / In Progress / Done）

- S0 Done — 任务初始化。
- S1 Planned — <方案/设计轮>。
- S2 Planned — <实现轮>。
- S3 Planned — <验证收口轮（对照 ACCEPTANCE）>。

## 4. 证据边界 / 禁止误称

- <继承工程级红线（TASK_INDEX 表②）+ 本任务特有边界>
- 未经授权不运行 <EDA 工具>、不生成 bitstream、不上板、不 git 写。

## 5. 待补证据 / 待决策 / 待授权

- <条目化；人工一行 FACT/决策即可销项>

## 6. 唯一下一步

<一句话 + 是否需独立授权>

## 7. 仓库要点

- 分支 `<branch>`，基线 `<hash>`；hard-readonly = `AGENT_RULES.md` / 本任务 `ACCEPTANCE.md`。
- 工作区脏改动 / 未跟踪文件：<只记录，agent 不清理>
