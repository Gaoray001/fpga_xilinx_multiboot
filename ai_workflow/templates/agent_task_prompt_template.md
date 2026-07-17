# Agent 任务 Prompt 模板

## 0. 固定入口

请严格按照工程接力工作流执行。

开始前必须阅读：

```text
ai_workflow/AGENT_RULES.md
ai_workflow/PROJECT_STATE.md
ai_workflow/HANDOFF_CURRENT.md
ai_workflow/TASK_INDEX.md
当前任务目录/TASK.md
当前任务目录/TASK_STATE.md
当前任务目录/ACCEPTANCE.md
当前任务目录/HANDOFF.md
```

当前任务状态以 `TASK_STATE.md` 为唯一事实来源。
`AGENT_RULES.md` 和 `ACCEPTANCE.md` 默认只读，未经明确授权不得修改。

开始前必须执行并记录：

```bash
git branch --show-current
git status --short
git diff --stat
git log --oneline -5
```

开始前允许状态：

```text
1. git status --short 为空；或
2. 只出现本轮 prompt 文件。
```

如出现其它未解释的 M / D / ??，必须停止。

本轮禁止自动执行：

```text
git commit
git reset
git clean
git stash
```

报告时间戳必须由命令生成：

```bash
TS=$(date +%Y%m%d_%H%M%S)
```

---

## 1. 本轮任务

任务名称：

```text
TODO
```

本轮目标：

```text
TODO
```

允许修改：

```text
TODO
```

禁止修改：

```text
TODO
```

实现要求：

```text
TODO
```

自检要求：

```text
TODO
```

报告路径：

```text
TODO
```

最终回复要求：

```text
TODO
```
