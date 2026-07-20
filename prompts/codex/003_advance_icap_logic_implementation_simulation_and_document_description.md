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
  ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/20260717_021312_multiboot_ctrl_fsm_xsim_report.md

- 当前尚未验证 ICAPE2 接入、ICAP 数据位序、WBSTAR/IPROG 真实接口发送及 FPGA 实际重配置。

- 本轮目标平台为 Xilinx 7 Series / Zynq-7000 PL 侧 ICAP，使用 ICAPE2。
- Linux 用于 RTL 开发和 XSim 仿真；Windows Hardware Manager 留待后续上板。
```

## GOAL

```text
1. 审查现有 Multiboot controller、命令流、Testbench 及 Shell/Tcl 仿真入口。

2. 核对当前命令流、ICAP 数据位序和 ICAPE2 接口要求。

3. 实现并连接以下 RTL 链路：
   Multiboot controller → ICAPE2 wrapper → ICAPE2 primitive

4. 建立自检型 Verilog Testbench，使用 Vivado 2018.3 XSim 和 UNISIM 完成真实编译、elaboration 和仿真。

5. 检查命令内容、顺序、数量、ICAP 控制信号、数据位序、reset、busy 和发送节拍。

6. 输出 RESULT=PASS 或 RESULT=FAIL，生成日志和 WDB，并更新任务状态及报告。
```

## HYPOTHESIS

```text
以下内容需要 Agent 自行验证：

1. 当前目标器件适用 ICAPE2。
2. 前置 Multiboot 命令序列适合通过 ICAPE2 发送。
3. Vivado 2018.3 本地安装包含所需 ICAPE2 / UNISIM 仿真模型。
4. ICAPE2 仿真只能验证接口和命令流，不能证明 FPGA 实际 Multiboot 成功。
```

## WRITE_ALLOW

```text
允许新增或修改.v文件
允许新增或修改.sh文件
允许新增或修改.tcl文件
允许更新 multiboot/ai_workflow 状态文件
允许增加 ai_workflow/tasks/20260717_multiboot_ctrl_fsm/reports/<TS>_xxx.md  (报告名自行确定)
```

## PREFERENCE

```text
- 保持现有工程结构，不做无关重构。
- 使用 Verilog、XSim 和 ICAPE2，不引入 SystemVerilog、其他仿真器或 ICAPE3。
- 优先复用已经通过仿真的 Multiboot controller。
- 器件无关控制逻辑与 ICAPE2 专用逻辑保持清晰边界。
- Testbench 必须自检，波形仅用于理解和定位。
- ICAP 相关结论优先依据 AMD/Xilinx 官方资料和本地 Vivado 2018.3 文件。
- 报告使用中文，说明实现原理、证据、仿真能力边界和后续上板缺口。
```

## RUN_POLICY

```text
R2：可运行且可修改。

允许：
- 在 WRITE_ALLOW 范围内修改文件
- 运行 Vivado 2018.3 batch、xvlog、xelab、xsim
- 使用 UNISIM / unisims_ver
- 运行必要的只读 Shell、Tcl 和 git 检查
- 生成日志、WDB 和仿真产物
```

## HARD_BOUNDARY

```text
- 不修改 WRITE_ALLOW 之外的文件。
- 不执行 git 写操作。
- 不运行综合、实现、bitstream、MCS 或 BIN 生成。
- 不写 Flash、不上板、不触发真实 FPGA 重配置。
- 不接入 ICAPE3，不扩展多器件通用框架，不提前实现 UDP 或镜像生成流程。
- 不得将 XSim 的 ICAPE2 接口仿真描述为真实 FPGA Multiboot 已通过。
- 若目标器件不适用 ICAPE2，停止实现并在报告中说明证据和阻塞原因。
```

## ACCEPTANCE

```text
1. 已确认目标器件与 ICAPE2 的适用性。

2. 已完成以下真实 RTL 链路：
   Multiboot controller → ICAPE2 wrapper → ICAPE2 primitive

3. 已核对并记录：
   - Multiboot 命令序列
   - WBSTAR / IPROG 写入
   - ICAPE2 数据位序转换
   - RTL 配置字与 ICAPE2 端口实际数据

4. 自检型 Testbench 已覆盖：
   - 命令内容、数量和顺序
   - ICAP 控制信号和数据
   - reset
   - busy 期间新请求
   - backpressure 或发送节拍

5. 已实际运行 xvlog、xelab 和 xsim，并有证据证明 ICAPE2 / UNISIM 参与仿真。

6. 最终日志包含真实 RESULT=PASS 或 RESULT=FAIL。

7. 通过时生成非空 WDB，并在报告中记录路径、打开方式和建议观察信号。


8. 报告记录：
   - 修改文件
   - 实际运行命令
   - 官方资料及本地工具依据
   - 仿真结果和证据
   - 仿真能够证明与不能证明的内容
   - 未执行事项、风险和下一步建议

9. 更新任务状态文件、交接文件和任务索引。


```