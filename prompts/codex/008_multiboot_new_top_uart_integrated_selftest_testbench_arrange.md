# Agent Task Prompt

执行 `ai_workflow/AGENT_RULES.md`。本轮只填写差量。

## FACT

```text
- 当前分支：dev
- 当前工程：/data/work/fpga/multiboot
- 活跃任务：ai_workflow/tasks/20260717_multiboot_ctrl_fsm

- 前置任务报告：
ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260719_232416_top_uart_xsim_report.md

- 本轮目标平台为 Xilinx 7 Series / Zynq-7000 PL 侧 ICAP，使用 ICAPE2。
- Linux 用于 RTL 开发和 XSim 仿真；Windows Hardware Manager 留待后续上板。
```

## GOAL

```text
1.本轮梳理工程实现的逻辑，目的是让我明白当前工程已经实现的逻辑。
2.
```

## HYPOTHESIS

```text
<无>
```

## WRITE_ALLOW

```text
允许更新 multiboot/ai_workflow 状态文件
允许增加 ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/<TS>_xxx.md  (报告名自行确定)
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
- 允许使用shell 查询只读类命令
```

## HARD_BOUNDARY

```text
- 允许增加报告说明 ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/<TS>_xxx.md
- 允许更新ai_workflow下状态文件
```

## ACCEPTANCE

```text
报告说明中需要回答
1.当前的顶层、子模块以及他们的调用逻辑与数据走向
2.仿真层对什么仿真？仿真的目的是什么？
3.激励的数据分别送入的是什么？testbench如何对子模块进行的仿真？
4.观察到什么样的信息是理想数据？则可以推进下一阶段编译上板？
```