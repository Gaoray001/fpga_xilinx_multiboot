你的理解基本正确。当前可以正式冻结技术路线和目录结构，开始推进 **Multiboot RTL + Linux XSim 仿真闭环**。

# 一、当前技术路线正式确定

## 1. Linux 是主开发平台

Linux 服务器负责：

```text
RTL 编写
Tcl 工程创建
Vivado 综合与实现
bit/ltx 生成
XSim 仿真
报告导出
Git 管理
AI Agent 执行
```

Windows 负责：

```text
Vivado Hardware Manager
JTAG 下载 bit
加载 ltx
ILA 在线抓取
板卡实际验证
```

这种划分没有问题。Linux 生成的 `.bit` 和 `.ltx` 可以复制到 Windows 使用。

但必须遵守三个约束：

1. Windows 和 Linux 最好都使用 **Vivado 2018.3**。
2. `.bit` 和 `.ltx` 必须来自同一次构建。
3. 每次构建要保留 Git commit、时间戳和调试开关信息。

建议最终产物按构建归档：

```text
_artifacts/
└── 20260717_230000_full/
    ├── Top.bit
    ├── Top.ltx
    ├── build_manifest.txt
    ├── timing_summary.rpt
    └── utilization.rpt
```

其中：

```text
build_manifest.txt
```

至少记录：

```text
git_commit=
git_branch=
vivado_version=
device_part=
build_type=
enable_debug=
bit_file=
ltx_file=
build_result=
```

这样不会在 Windows 上出现“bit 和 ltx 对不上”的问题。

---

# 二、波形查看路线确定

你采用两套波形方案是合理的。

## 主方案：XSim WDB + Vivado Waveform

适用于：

* 完整 Vivado 工程。
* Xilinx 原语。
* ICAPE2、ICAPE3。
* Vivado IP。
* 大规模 RTL 仿真。
* 需要保存 Vivado 波形布局的场景。

文件关系：

```text
.wdb    仿真波形数据库
.wcfg   波形窗口布局配置
```

推荐提交：

```text
sim/wave/*.wcfg
```

不推荐提交：

```text
*.wdb
xsim.dir/
```

查看方式可以是：

```text
Linux Vivado GUI
NoMachine/VNC
必要时将 WDB 复制到同版本 Windows Vivado
```

## 辅助方案：VCD/FST + GTKWave

适用于：

* 小型纯 RTL 模块。
* 状态机。
* FIFO 控制。
* 握手逻辑。
* 不依赖大量 Xilinx IP 的模块。

建议当前优先级：

```text
第一优先级：XSim WDB
第二优先级：VCD/FST + GTKWave
```

本轮不引入 ModelSim，避免同时维护两套编译库、do 文件和仿真入口。

---

# 三、当前工作区结构评估

你当前目录：

```text
/data/work/fpga/multiboot
```

结构已经具备以下分层：

| 目录             | 职责                |
| -------------- | ----------------- |
| `rtl/`         | 可综合设计源码           |
| `sim/`         | Testbench 和仿真相关文件 |
| `constraints/` | XDC 约束            |
| `tcl/build/`   | Vivado 工程创建和构建流程  |
| `tcl/debug/`   | ILA 插入            |
| `tcl/ip/`      | IP 创建和管理          |
| `scripts/`     | Shell 总入口         |
| `_runs`        | 临时运行结果            |
| `_artifacts`   | 正式交付产物            |
| `reports/`     | AI 和人工分析报告        |
| `ai_workflow/` | Agent 接力状态        |
| `tools/`       | Python 等独立工具      |
| `docs/`        | 长期工程文档            |

**这套目录可以冻结，不需要重新设计。**

后续只添加 Multiboot 和仿真所需子目录。

---

# 四、建议补充的目录

基于你的现有结构，推荐增加：

```text
rtl/
└── hdl/
    └── user/
        └── multiboot/
            ├── multiboot_ctrl.v
            ├── multiboot_icap_if.v
            ├── multiboot_icap_model.v
            ├── multiboot_icap_7series.v
            └── multiboot_icap_ultrascale.v

sim/
├── tb/
│   └── multiboot/
│       ├── tb_multiboot_ctrl.v
│       └── tb_multiboot_top.v
├── xsim/
│   ├── run_multiboot.tcl
│   └── dump_multiboot_vcd.tcl
└── wave/
    └── tb_multiboot_ctrl.wcfg

tcl/
└── sim/
    ├── 00_prepare_sim.tcl
    ├── 10_sim_multiboot_ctrl.tcl
    └── common_sim_utils.tcl
```

完整关系：

```text
scripts/vivado2018_common.sh
          │
          ├── create
          │      └── tcl/build/01_create_project.tcl
          │
          ├── synth
          │      └── tcl/build/10_synth.tcl
          │
          ├── impl
          │      └── tcl/build/20_impl.tcl
          │
          ├── full
          │      └── tcl/build/40_full_build.tcl
          │
          └── sim
                 └── tcl/sim/10_sim_multiboot_ctrl.tcl
```

`build` 和 `sim` 应分开：

```text
tcl/build/    生成 FPGA 实际实现结果
tcl/sim/      生成和运行仿真
```

不要把大量仿真控制代码放入 `40_full_build.tcl`。

---

# 五、本次 Multiboot 开发范围

本轮不要马上把 UDP、Flash、ICAP、双镜像全部一次完成。

应先验证最小控制链：

```text
boot_req
   │
   ▼
multiboot_ctrl
   │
   ├── 产生 WBSTAR 写入序列
   └── 产生 IPROG 命令序列
             │
             ▼
multiboot_icap_model
             │
             ▼
Testbench 自动检查
```

第一阶段不连接真实网口，也不尝试在仿真中真正重新配置 FPGA。

原因是需要分别验证：

```text
控制逻辑正确
ICAP 命令正确
网口命令解析正确
Flash 镜像布局正确
```

混在一起出现错误时很难定位。

---

# 六、RTL 建议分层

## 1. `multiboot_ctrl.v`

这是本轮重点，也用于验证 Verilog Skill。

模块只处理：

* 接收启动请求。
* 锁存目标地址。
* 产生 ICAP 写数据。
* 管理状态机。
* 防止重复请求。
* 输出 busy、done、error。
* 超时保护。

建议抽象接口：

```verilog
module multiboot_ctrl #(
    parameter WBSTAR_WIDTH = 32
)(
    input  wire                    clk,
    input  wire                    rst,

    input  wire                    boot_req,
    input  wire [WBSTAR_WIDTH-1:0] boot_addr,

    output reg                     boot_busy,
    output reg                     boot_done,
    output reg                     boot_error,

    output reg                     icap_valid,
    output reg  [31:0]             icap_data,
    input  wire                    icap_ready
);
```

这里先不要直接实例化 `ICAPE2` 或 `ICAPE3`。

---

## 2. `multiboot_icap_model.v`

仅用于仿真。

它负责：

* 接收 `icap_valid`。
* 记录命令字。
* 模拟 `icap_ready`。
* 检测是否写入预期 WBSTAR 地址。
* 检测是否发送 IPROG。
* 向 Testbench 暴露检查状态。

例如：

```verilog
output reg        wbstar_seen;
output reg [31:0] captured_wbstar;
output reg        iprog_seen;
```

这样 Testbench 不需要依赖复杂的层次引用。

---

## 3. 器件专用 ICAP 文件

真正上板时再选择：

```text
Kintex-7 / Artix-7 / Zynq-7000
    → multiboot_icap_7series.v
    → ICAPE2
```

```text
Kintex UltraScale KU040
    → multiboot_icap_ultrascale.v
    → ICAPE3
```

不要在一个源码文件中无条件同时实例化 `ICAPE2` 和 `ICAPE3`。

建议由 Tcl 根据器件类型添加对应文件：

```tcl
if {[string match "xc7*" $FPGA_PART]} {
    add_files $RTL_DIR/multiboot/multiboot_icap_7series.v
} elseif {[string match "xcku*" $FPGA_PART]} {
    add_files $RTL_DIR/multiboot/multiboot_icap_ultrascale.v
} else {
    error "Unsupported FPGA part for Multiboot: $FPGA_PART"
}
```

---

# 七、第一轮 Testbench 验收内容

第一轮 `tb_multiboot_ctrl.v` 建议至少完成以下测试。

## Case 1：切换到 bit2

```text
boot_req = 1
boot_addr = BIT2_FLASH_ADDR
```

检查：

```text
WBSTAR 地址正确
IPROG 命令出现
boot_busy 正确拉高
boot_done 正确产生单周期脉冲
```

## Case 2：切换回 bit1

```text
boot_addr = BIT1_FLASH_ADDR
```

检查目标地址已经改变。

## Case 3：busy 期间重复请求

在状态机运行过程中再次产生 `boot_req`。

预期：

```text
不重新开始
不覆盖当前 boot_addr
只出现一套 ICAP 命令
```

## Case 4：复位中断

命令执行到一半时拉高 reset。

预期：

```text
状态机返回 IDLE
icap_valid 清零
busy 清零
不能继续发送 IPROG
```

## Case 5：ICAP backpressure

让 `icap_ready` 间歇性拉低。

预期：

```text
icap_data 保持不变
状态机不能跳过命令字
命令顺序保持正确
```

## Case 6：非法地址

建议在控制器中加入可配置地址检查，或者至少在上层限制。

预期：

```text
boot_error = 1
不发送 IPROG
```

---

# 八、仿真必须是自检型，而不是只看波形

Testbench 最终必须输出：

```text
TEST=boot_to_image2 RESULT=PASS
TEST=boot_to_image1 RESULT=PASS
TEST=busy_reject RESULT=PASS
TEST=reset_abort RESULT=PASS
TEST=icap_backpressure RESULT=PASS
TOTAL_ERRORS=0
RESULT=PASS
```

出现错误时：

```text
ERROR: expected WBSTAR=0x00800000 actual=0x00400000
RESULT=FAIL
```

Shell 脚本读取仿真退出码和日志：

```text
exit_status=0
result=SUCCESS
sim_result=PASS
testbench_errors=0
```

不能仅仅做到：

```text
打开波形后人工判断似乎正确
```

波形用于定位，自检结果用于验收。

---

# 九、XSim 建议分两阶段掌握

## 阶段 A：Vivado 工程模式仿真

首先使用已经创建的 Vivado 工程：

```tcl
open_project ...
set_property top tb_multiboot_ctrl [get_filesets sim_1]
launch_simulation
run all
```

优点：

* 自动处理 Vivado 库。
* 自动处理工程源文件。
* 容易查看 WDB。
* 适合当前刚建立 Tcl 工程的阶段。

## 阶段 B：独立命令行仿真

工程模式稳定后，再练习：

```bash
xvlog
xelab
xsim
```

典型调用链：

```bash
xvlog \
    rtl/hdl/user/multiboot/multiboot_ctrl.v \
    rtl/hdl/user/multiboot/multiboot_icap_model.v \
    sim/tb/multiboot/tb_multiboot_ctrl.v

xelab tb_multiboot_ctrl \
    -s tb_multiboot_ctrl_sim \
    --debug typical

xsim tb_multiboot_ctrl_sim \
    -tclbatch sim/xsim/run_multiboot.tcl \
    -wdb multiboot_ctrl.wdb
```

这两个阶段都完成后，你才算真正掌握 XSim 的基本使用：

```text
工程模式
独立编译模式
日志分析
WDB 查看
VCD 导出
Testbench 自检
Shell 捕获退出码
```

---

# 十、当前工程推进顺序

建议按下面顺序执行，不要跳跃。

## 任务 1：验证工程模板

执行：

```bash
cd /data/work/fpga/multiboot

./scripts/vivado2018_common.sh create
```

或者你当前脚本定义的等价入口。

确认：

```text
工程可以从零创建
路径无 Windows 绝对路径
RTL、XDC、仿真 fileset 正确
Vivado 无需人工补文件
```

## 任务 2：建立最小 XSim 冒烟测试

先写一个非常简单的：

```text
multiboot_ctrl 空壳
tb_multiboot_ctrl
```

验证：

```text
Shell → Tcl → XSim → Testbench → PASS
```

这一阶段的重点是调度链，而不是 ICAP 功能。

## 任务 3：实现抽象 Multiboot 状态机

加入：

```text
WBSTAR 命令序列
IPROG 命令序列
ready/valid 握手
busy/done/error
```

## 任务 4：完成自检 Testbench

覆盖前面六个测试场景。

## 任务 5：接入器件专用 ICAP

根据最终验证板卡选择：

```text
ICAPE2
或
ICAPE3
```

## 任务 6：生成两个最小镜像

先使用不同 LED 闪烁频率或版本寄存器区分：

```text
bit1：IMAGE_ID = 32'h0000_0001
bit2：IMAGE_ID = 32'h0000_0002
```

## 任务 7：加入 UDP 指令

最后才将：

```text
UDP command
    ↓
boot_req / boot_addr
```

接入已经验证通过的 Multiboot 控制器。

---

# 十一、本轮明确边界

本轮核心目标是：

```text
Linux 平台设计
+ Tcl 工程新建
+ Shell/Tcl 调度
+ Verilog RTL
+ 自检 Testbench
+ XSim 仿真
+ WDB 波形查看
```

本轮暂时不需要同时处理：

```text
ModelSim 安装
复杂 UDP 协议栈
正式 Flash 地址布局
Golden Image fallback
完整原工程迁移
大规模 ILA 调试
```

因此，当前第一个可执行的小目标应定义为：

> 在现有 `/data/work/fpga/multiboot` 工作区中，建立 `multiboot_ctrl` 的最小 RTL 和自检 Testbench，通过 `vivado2018_common.sh sim` 调度 XSim，在 `_runs` 中生成日志与 WDB，并输出 `RESULT=PASS`。

完成这一小目标后，再开始写真实的 WBSTAR/IPROG 命令序列。
