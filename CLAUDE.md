# CLAUDE.md — multiboot 项目常驻铁律（Claude）

> 本文件每轮自动常驻，只放不可忘红线（保持 ≤40 行）。完整流程细则见 `ai_workflow/AGENT_RULES.md`。

## 每轮第一件事

1. 先读 `ai_workflow/HANDOFF_CURRENT.md`（第一屏：当前事实 + 唯一下一步）。
2. 当前任务的长期事实以该任务目录下 `TASK_STATE.md` 为**唯一事实来源**；其它状态文件只是摘要/指针，冲突时以 `TASK_STATE.md` 为准。

## Git 红线（settings.local.json 已硬拦，勿绕过）

- 禁止自动 `git commit` / `git reset` / `git clean` / `git stash`；提交与否由人类审 report + diff 后决定。
- 不得清理、覆盖、回滚用户未授权的脏改动；只记录，不动手。

## 证据边界（<按本工程填写，删除本行提示>）

- <示例：仿真 PASS ≠ 上板 PASS>
- <示例：`ENABLE_DEBUG=0` 功能构建 timing clean 才是功能 timing 判据；debug build 违例 ≠ 功能失败>
- <示例：接口有响应 ≠ 数据值正确>

## 节奏

- 每轮只推进一个 gate；一轮一小步、最小改动集。
- 人类 prompt 只表达本轮差量意图（FACT/GOAL/BOUNDARY）。
- 未经本轮明确授权，不运行 <EDA 工具>、不生成 bitstream、不上板、不改 IP。

## Skill（按需领域方法，命中描述才展开）

- Claude 专用 skill 位于 `.claude/skills/`：
  - `fpga-rtl-rules` — 新增/修改/审查 RTL、CDC、AXI、valid-ready、FSM、reset 时。
  - `ila-debug-build` — ILA / debug build / probe / XDC / timing 边界时。
