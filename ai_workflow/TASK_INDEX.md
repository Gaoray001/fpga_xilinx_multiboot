# 任务索引与跨任务事实

> 表① = 任务注册表（不是工作历史；轮次历史在各任务 `reports/` + git log）。
> 表② = 所有任务共享的硬事实与证据红线（任务级事实在各自 `TASK_STATE.md`）。
> 本文件由 agent 维护。

## 表① 任务总表

| 任务 | 状态 | 分支 | 下一步（一句话） | 事实源 |
|---|---|---|---|---|
| 20260717_xsim_smoke_test | ACTIVE | dev | 人工审查本任务 diff/report；若继续技术推进，另起一轮定义 Multiboot 功能级仿真目标。 | `tasks/20260717_xsim_smoke_test/TASK_STATE.md` |

## 表② 跨任务硬事实与证据红线

### 硬事实（工具链/架构级，所有任务适用）

| 事实 | 证据 |
|---|---|
| <示例：主时钟 = xxx MHz；工具链 = Vivado 20xx.x> | <report/commit 指针> |

### 证据红线（禁止误称，所有任务适用）

- 静态检查通过不等于 XSim 运行通过。
- 仿真 PASS 不等于上板 PASS。
- 未真实生成 `.wdb` 文件，不得声称 WDB 已成功生成。

### 平台分工

- Linux = 批处理构建、仿真、状态归档。
- Windows = Vivado Hardware Manager、bit/ltx 下载和板卡调试。

## 规则入口（指针）

- 常驻铁律：根 `CLAUDE.md`（Claude）/ `AGENTS.md`（Codex）；流程细则：`ai_workflow/AGENT_RULES.md`（hard-readonly）。
- 领域方法：`.claude/skills/` · `.agents/skills/`；模板：`ai_workflow/templates/`。
