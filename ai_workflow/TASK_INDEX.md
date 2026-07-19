# 任务索引与跨任务事实

> 表① = 任务注册表（不是工作历史；轮次历史在各任务 `reports/` + git log）。
> 表② = 所有任务共享的硬事实与证据红线（任务级事实在各自 `TASK_STATE.md`）。
> 本文件由 agent 维护。

## 表① 任务总表

| 任务 | 状态 | 分支 | 下一步（一句话） | 事实源 |
|---|---|---|---|---|
| 20260717_xsim_smoke_test | DONE | dev | 作为 XSim smoke 基线保留；后续不再以 smoke PASS 代表 Multiboot 功能。 | `tasks/20260717_xsim_smoke_test/TASK_STATE.md` |
| 20260717_multiboot_ctrl_fsm | ACTIVE | dev | 人工审查本任务 diff/report；若继续推进，另起一轮定义真实 ICAP/Flash/上板边界或更高层功能仿真目标。 | `tasks/20260717_multiboot_ctrl_fsm/TASK_STATE.md` |

## 表② 跨任务硬事实与证据红线

### 硬事实（工具链/架构级，所有任务适用）

| 事实 | 证据 |
|---|---|
| Linux XSim 工具链使用 Vivado 2018.3。 | `tasks/20260717_multiboot_ctrl_fsm/reports/20260717_021312_multiboot_ctrl_fsm_xsim_report.md` |
| `_artifacts/latest` 表示最近一次成功且产物完整的 artifact 目录；失败运行不得覆盖。 | `ai_workflow/AGENT_RULES.md` / `tasks/20260717_multiboot_ctrl_fsm/reports/20260717_021312_multiboot_ctrl_fsm_xsim_report.md` |

### 证据红线（禁止误称，所有任务适用）

- 静态检查通过不等于 XSim 运行通过。
- 仿真 PASS 不等于上板 PASS。
- 未真实生成 `.wdb` 文件，不得声称 WDB 已成功生成。
- 抽象 Multiboot 状态机仿真 PASS 不等于真实 ICAP/Flash/上板 Multiboot PASS。

### 平台分工

- Linux = 批处理构建、仿真、状态归档。
- Windows = Vivado Hardware Manager、bit/ltx 下载和板卡调试。

## 规则入口（指针）

- 常驻铁律：根 `CLAUDE.md`（Claude）/ `AGENTS.md`（Codex）；流程细则：`ai_workflow/AGENT_RULES.md`（hard-readonly）。
- 领域方法：`.claude/skills/` · `.agents/skills/`；模板：`ai_workflow/templates/`。
