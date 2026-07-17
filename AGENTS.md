# AGENTS.md — multiboot 项目入口（Codex）

> 本文件是 Codex 的项目入口，放不可忘的项目铁律（与 `CLAUDE.md` 内容对齐）。
> 完整流程细则见 `ai_workflow/AGENT_RULES.md`。

## 每轮第一件事

1. 先读 `ai_workflow/HANDOFF_CURRENT.md`（第一屏：当前事实 + 唯一下一步）。
2. 当前任务长期事实以任务目录 `TASK_STATE.md` 为**唯一事实来源**。

## Git 红线

- 禁止自动 `git commit` / `git reset` / `git clean` / `git stash`；提交由人类审 report + diff 后决定。
- 不得清理、覆盖、回滚用户未授权的脏改动；只记录，不动手。

## 证据边界（<按本工程填写，与 CLAUDE.md 保持一致>）

- <边界 1>
- <边界 2>

## 节奏

- 每轮只推进一个 gate；一轮一小步、最小改动集。
- 未经本轮明确授权，不运行 <EDA 工具>、不生成 bitstream、不上板、不改 IP。

## Skill（按需领域方法）

- Codex 专用 skill 位于 `.agents/skills/`：`fpga-rtl-rules` / `ila-debug-build`（内容与 `.claude/skills/` 对齐）。

## 多 agent 接力

- Claude 与 Codex 的状态接力**只**通过 `ai_workflow/` 状态文件和 reports 进行，不得依赖各自私有记忆。
