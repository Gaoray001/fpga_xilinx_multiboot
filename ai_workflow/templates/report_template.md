# Report 模板（分级：轻型 / 重型）

> 报告分档以本轮 `RUN_POLICY` 运行等级为准，对齐 R0/R1/R2：
> - **R0（只读分析 / 状态同步 / prompt·workflow 小调整 / 小范围脚本结果）→ 轻型**
> - **R1（可运行验证但不改工程逻辑）→ 中型**（轻型 + 命令记录 + 验证结果）
> - **R2（改 RTL/Tcl/XDC/Python、跑 Vivado、上板、发 UDP、影响功能路径）→ 重型**
>
> 报告文件名：`reports/<agent>/<TS>_<slug>_report.md` 或任务 `reports/<TS>_<slug>_report.md`，
> `TS=$(date +%Y%m%d_%H%M%S)`。单一事实来源仍是任务 `TASK_STATE.md`，报告不覆盖它。

---

## A. 轻型 report（R0 / 状态同步 / 小调整）

字段不超过 5–7 项：

```markdown
# 报告：<标题>

- AI 模型类型：<claude / codex / ...>
- 时间戳：<TS>
- 轮次性质：<R0 只读 / 状态同步 / workflow 调整 / 脚本结果>

## 1. 本轮目标
<一两句>

## 2. 实际修改 / 未修改
<改了哪些文件；未改哪些关键类别（RTL/Tcl/XDC/Python/MIG/IP）>

## 3. 证据 / 结果
<只读发现 / 脚本输出 / self-test 结果；无则写“无新增工程结论”>

## 4. 风险与边界
<证据边界；不得误称项；dirty workspace 记录>

## 5. 下一步
<唯一下一步动作 + 是否需独立授权>
```

轻型仍必须包含一行 **FPGA yes/no 摘要**（改 RTL/XDC/Tcl/Python? 跑 Vivado? 上板? 发 UDP? 改 MIG/IP? git 写?），可压缩为一句“全部否”。

---

## B. 重型 report（R2 / 改代码 / Vivado / 上板 / UDP / 影响功能路径）

保留 `AGENT_RULES §5` 完整必填结构：

```markdown
# 报告：<标题>

- AI 模型类型 / 时间戳 / 本轮任务

## git baseline
branch / status --short / diff --stat / recent log

## 输入事实摘要
## latest report 发现结果（含指针漂移核验）

## 边界自检
- 本轮 WRITE_ALLOW / ALLOWLIST
- 本轮 RUN_POLICY / COMMAND_ALLOW / COMMAND_DENY
- 本轮 OVERRIDE_BOUNDARY
- 实际修改文件 / 实际运行命令
- 是否触碰禁止项 / 是否改 hard-readonly / 是否有额外自主修改
- 是否越界：yes/no

## 修改摘要 / 实际改动文件 / 额外自主修改说明
## 验证情况（命令记录 + 结果 + 通过判据）
## 未执行事项
## 风险与注意事项
## 回滚说明（改了什么、如何还原、影响 legacy path 否）
## 下一轮建议 / 待授权事项

## FPGA 调试 yes/no 状态
- 改 RTL / XDC / Tcl / Python
- 跑 Vivado / 生成 bitstream
- 上板 / 发送真实 UDP 包
- 改 MIG/IP
- git commit/reset/clean/stash
（任一 yes：说明做了什么、为何被授权、证据位置、风险）

## 最终 git status --short / git diff --stat
```

---

## 选档速查

| 轮类型 | 档 |
|---|---|
| 只读审计 / 分析 / 复盘 | 轻型 |
| 状态同步 / handoff 整理 / workflow 调整 | 轻型 |
| 本地 Python self-test / 脚本小结果 / 语法检查 | 轻型（R0/R1） |
| 可运行验证但不改工程逻辑 | 中型（轻型 + 命令 + 验证） |
| 改 RTL/Tcl/XDC/Python 工程脚本 | 重型 |
| 跑 Vivado build / 生成 bitstream | 重型 |
| 上板 / 发 UDP / 影响功能路径 | 重型 |
