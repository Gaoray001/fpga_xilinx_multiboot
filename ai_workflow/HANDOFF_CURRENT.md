# 当前工程交接（下一位 agent 第一屏）

> 只放第一屏；唯一事实源 = 当前任务 `TASK_STATE.md`（纯快照，agent 专用）。
> 本文件每轮全量重写，硬上限 30 行。时间戳：20260719_194352

## 当前任务

20260717_multiboot_ctrl_fsm — S5 Flash/镜像布局/WBSTAR 方案已定义。

## 关键现状（详见任务 TASK_STATE §2）

- 已实现 `multiboot_ctrl → multiboot_icape2_wrapper → ICAPE2`，抽象 controller 未绑定器件原语。
- wrapper 使用 X32 ICAPE2，实际写拍 `CSIB=0` / `RDWRB=0`，配置字逐 byte bit-reversal。
- 自检 TB 覆盖顺序/数量/物理数据、reset、busy 新请求、backpressure、UNISIM WBSTAR/IPROG 解码。
- 最终 run `20260719_024313_xsim-multiboot-ctrl`：`RESULT=PASS`，xelab 含 `unisims_ver.ICAPE2/SIM_CONFIGE2`。
- WDB：`_artifacts/common_vivado/20260719_024313_xsim-multiboot-ctrl/multiboot_ctrl.wdb`，44104 bytes。
- S5 目标硬件固定：`xc7a35tfgg484-2` + `N25Q128A13ESE40G` 16 MiB + Master SPI x4。
- Golden offset/WBSTAR=`0x00000000`；Application offset/WBSTAR=`0x00800000`。
- 每镜像规划上限 4 MiB；两者间保留 4 MiB guard；默认上电运行 Golden。
- 第一阶段 UART 运行时触发 ICAPE2；不嵌入自动 IPROG，Ethernet 触发后移。
- 本轮只完成方案和状态收口；未改代码、未运行 Vivado、未生成 bitstream/MCS、未上板。
- `Top.v` 仍为空；UART pins、输入时钟和板上 mode straps 尚待确认。

## 下一步唯一动作

人工审查 S5 方案报告并补齐 UART/时钟/mode strap 事实；然后另起 S6 Top + UART 集成 gate。

## 最新 report 指针

- `ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260719_194352_multiboot_flash_layout_solution_report.md`
