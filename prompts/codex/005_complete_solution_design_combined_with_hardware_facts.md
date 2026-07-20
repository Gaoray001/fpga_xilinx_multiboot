# Agent Task Prompt

执行 `ai_workflow/AGENT_RULES.md`。本轮只填写差量。

## FACT

```text
- 当前分支：dev
- 当前工程：/data/work/fpga/multiboot
- 活跃任务：ai_workflow/tasks/20260717_multiboot_ctrl_fsm

- 前置任务报告：
 ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260719_183228_multiboot_logic_sortout_report.md

- 本轮目标平台为 Xilinx 7 Series / Zynq-7000 PL 侧 ICAP，使用 ICAPE2。
- Linux 用于 RTL 开发和 XSim 仿真；Windows Hardware Manager 留待后续上板。

硬件板卡事实:
- SPI_FLASH:N25Q128A13ESE40G (16M字节)
- FPGA:xc7a35tfgg484-2
```

## GOAL

```text
1.本轮推进 Flash 模式 / 镜像布局 / WBSTAR 编码定义

2.触发源第一轮为串口触发，后续再推进网口触发
```

## HYPOTHESIS

```text
本轮推进完成下面的方案设计，将以LED等不同频率闪烁工程为两种bit烧写

目标 FPGA：
配置模式：
Flash 型号：
Flash 容量：

golden byte offset：
application byte offset：

golden WBSTAR payload：
application WBSTAR payload：

bitstream 最大预估大小：
镜像间安全间隔：

默认启动镜像：
失败恢复方法：
首次烧写步骤：
回滚步骤：
```

## WRITE_ALLOW

```text
- 允许更新 multiboot/ai_workflow 状态文件
- 允许增加 ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/<TS>_xxx.md  (报告名自行确定)
- 不允许推进代码实现
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
- 生成报告--应结合硬件事实完成方案设计
- 更新ai_workflow报告
```