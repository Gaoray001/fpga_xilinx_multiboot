# Agent Task Prompt

执行 `ai_workflow/AGENT_RULES.md`。本轮只填写差量。

## FACT

```text
- 当前分支：dev
- 当前工程：/data/work/fpga/multiboot
- 活跃任务：ai_workflow/tasks/20260717_multiboot_ctrl_fsm

- 前置任务报告：
ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260720_003126_top_uart_logic_and_tb_arrangement_report.md

- 人为执行 scripts/vivado2018_common.sh 已成功生成bit流
- 无时序报错
```

## GOAL

```text
1.本轮推进上板卡验证阶段，给出指导说明
2.增加一个shell脚本 scripts/open_latest_wbd.sh 
```

## HYPOTHESIS

```text
<无>
```

## WRITE_ALLOW

```text
允许更新 multiboot/ai_workflow 状态文件
允许增加 ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/<TS>_xxx.md  (报告名自行确定)
允许新增 脚本 scripts/open_latest_wbd.sh
```

## PREFERENCE

```
<无>
```

## RUN_POLICY

```text
R1：可运行且可修改。

允许：
- 允许使用git 查询只读类命令
- 允许使用shell 非删除类命令
- 允许使用tcl 非删除类命令
```

## HARD_BOUNDARY

```text
- 允许增加报告说明 ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/<TS>_xxx.md
- 允许更新ai_workflow下状态文件
```

## ACCEPTANCE

```text
报告说明中需要回答
1.如何烧录两个bit并烧录板卡？给出相应的指导说明

新增脚本要求：
调用脚本可操作vivado快速打开：   _artifacts/latest/*.wdb 波形
```