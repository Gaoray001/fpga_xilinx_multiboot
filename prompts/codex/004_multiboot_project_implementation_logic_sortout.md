 
# Agent Task Prompt

执行 `ai_workflow/AGENT_RULES.md`。本轮只填写差量。

## FACT

```text
- 当前分支：dev
- 当前工程：/data/work/fpga/multiboot
- 活跃任务：ai_workflow/tasks/20260717_multiboot_ctrl_fsm

- 前置任务已完成 Multiboot 抽象状态机及 XSim 功能仿真，真实调用链已验证：
  Shell → Tcl → xvlog → xelab → xsim → Verilog Testbench → RESULT=PASS

- 前置任务报告：
 ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260719_024339_multiboot_icape2_xsim_report.md
- 当前尚未验证 ICAPE2 接入、ICAP 数据位序、WBSTAR/IPROG 真实接口发送及 FPGA 实际重配置。

- 本轮目标平台为 Xilinx 7 Series / Zynq-7000 PL 侧 ICAP，使用 ICAPE2。
- Linux 用于 RTL 开发和 XSim 仿真；Windows Hardware Manager 留待后续上板。
```

## GOAL

```text
1.本轮梳理工程实现的逻辑，目的是让我明白当前工程已经实现的逻辑。
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
2.仿真层对谁仿真？仿真的目的是什么？
3.下一步应该推进什么？什么时候开始编译上板卡？
```