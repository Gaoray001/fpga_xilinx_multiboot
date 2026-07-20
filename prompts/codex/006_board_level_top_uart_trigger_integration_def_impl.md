# Agent Task Prompt

执行 `ai_workflow/AGENT_RULES.md`。本轮只填写差量。

## FACT

```text
- 当前分支：dev
- 当前工程：/data/work/fpga/multiboot
- 活跃任务：ai_workflow/tasks/20260717_multiboot_ctrl_fsm

- 前置任务报告：
 ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260719_194352_multiboot_flash_layout_solution_report.md

- 本轮目标平台为 Xilinx 7 Series / Zynq-7000 PL 侧 ICAP，使用 ICAPE2。
- Linux 用于 RTL 开发和 XSim 仿真；Windows Hardware Manager 留待后续上板。

硬件板卡事实:
- SPI_FLASH:N25Q128A13ESE40G (16M字节)
- FPGA:xc7a35tfgg484-2
- N17 UART1_TX  P17 UART1_RX  IOSTANDARD LVCMOS33
- 时钟 W19 50MHz 复位 N15 低电平有效
```

## GOAL

```text
1.推进板级 Top + UART 触发集成定义/实现
```

## HYPOTHESIS

```text
<无>
```

## WRITE_ALLOW

```text
- 允许更新 multiboot/ai_workflow 状态文件
- 允许增加 ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/<TS>_xxx.md  (报告名自行确定)
- 允许修改 Top/UART/LED RTL、XDC 和相应 TB/Tcl
```

## PREFERENCE

```
<无>
```

## RUN_POLICY

```text
R2：可运行且可修改。

允许执行非删除类shell命令
不允许运行vivado
不允许git写
```

## HARD_BOUNDARY

```text
- 允许增加报告说明 ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/<TS>_xxx.md
- 允许更新ai_workflow下状态文件
```

## ACCEPTANCE

```text
1.完成板级Top+UART触发定义实现
2.完成代码静态自检
```