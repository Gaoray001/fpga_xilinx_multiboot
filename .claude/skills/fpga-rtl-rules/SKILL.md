---
name: fpga-rtl-rules
description: Verilog/SystemVerilog RTL 代码风格规范。用于新增、修改或审查 RTL 文件的模块命名、端口命名、时钟复位、参数、always 块、FSM、valid-ready、AXI/AXIS、例化和注释格式。不包含项目实时状态、验证流程、Vivado/ILA 调试流程或权限规则。
---

# FPGA RTL 代码风格规范

本规范只定义 Verilog/SystemVerilog RTL 的代码书写风格。范围包括模块声明、端口命名、时钟复位、参数、always 块、FSM、valid-ready、AXI/AXIS、例化和注释格式。

本规范不描述项目实时状态、验证结论、Vivado/ILA 调试流程、上板流程、git 权限或 report 要求。

---

## 1. 基本风格

### 1.1 缩进

- 使用 4 个空格缩进。
- 不使用 tab。
- `begin` / `end` 独占结构清晰。
- 同一层级的 `if` / `else` / `case` 对齐。
- 连续端口、参数、信号声明按列对齐。

推荐格式：

```verilog
always @(posedge C_gclk_100M_i) begin
    if (R_gclk_100M_rst_i) begin
        data_cnt_r <= {LP_CNT_W{1'b0}};
    end
    else begin
        if (data_valid_i && data_ready_o) begin
            data_cnt_r <= data_cnt_r + 1'b1;
        end
    end
end
```

### 1.2 空行

- 模块头、参数、端口、内部信号、组合逻辑、时序逻辑、例化之间用空行分隔。
- 一个功能块内部不插入过多空行。
- 大段逻辑之间用注释块分隔。

### 1.3 注释

推荐使用功能分组注释：

```verilog
// ============================================================
// Parameter
// ============================================================

// ============================================================
// Internal signal
// ============================================================

// ============================================================
// FSM
// ============================================================

// ============================================================
// Sequential logic
// ============================================================
```

普通信号注释写在声明右侧或上一行，保持简短：

```verilog
wire        rd_fire_w;      // read handshake
reg  [7:0]  beat_cnt_r;     // beat counter in one burst
```

---

## 2. 文件与模块命名

### 2.1 文件名

- 新增 RTL 文件名使用 lower_snake_case。
- 文件名与主模块名保持一致。

示例：

```text
ddr3_da_read_engine.v
axis_rate_adapter.v
cdc_pulse_sync.v
```

### 2.2 模块名

- 新增普通内部模块使用 lower_snake_case。
- 顶层、legacy wrapper、IP wrapper 可保持原工程命名。
- 不为了风格统一批量重命名已验证模块。

示例：

```verilog
module ddr3_da_read_engine #(
    parameter integer P_DATA_W    = 512,
    parameter integer P_ADDR_W    = 32,
    parameter integer P_BURST_LEN = 16
)(
    ...
);
```

---

## 3. 端口命名

### 3.1 方向后缀

所有新增模块端口使用方向后缀：

| 方向 | 后缀 |
|---|---|
| input | `_i` |
| output | `_o` |
| inout | `_io` |

示例：

```verilog
input  wire         start_i,
output wire         done_o,
inout  wire [15:0]  ddr_dq_io
```

### 3.2 时钟端口

全局或主要时钟使用 `C_*` 前缀。模块端口仍带方向后缀 `_i`。

格式：

```text
C_<domain>_<freq>_i
```

示例：

```verilog
input wire C_gclk_100M_i,
input wire C_gclk_20M_i
```

顶层或工程全局网名可保持既有形式，例如：

```verilog
wire C_gclk_100M;
wire C_gclk_20M;
```

### 3.3 复位端口

复位使用 `R_*` 前缀。模块端口仍带方向后缀 `_i`。

格式：

```text
R_<domain>_rst_i
R_<domain>_rst_n_i
```

示例：

```verilog
input wire R_gclk_100M_rst_i,
input wire R_gclk_20M_rst_i
```

顶层或工程全局复位网名可保持既有形式，例如：

```verilog
wire R_gclk_100M_rst;
wire R_gclk_20M_rst;
```

推荐：

- `_rst_i` 表示高有效复位。
- `_rst_n_i` 表示低有效复位。
- 同一模块内只使用一种复位极性。
- 复位信号所在时钟域要从名称中体现。

### 3.4 数据信号端口

推荐后缀：

| 语义 | 命名 |
|---|---|
| 数据 | `*_data_i`, `*_data_o` |
| 有效 | `*_valid_i`, `*_valid_o` |
| 准备 | `*_ready_i`, `*_ready_o` |
| 最后一拍 | `*_last_i`, `*_last_o` |
| 使能 | `*_en_i`, `*_en_o` |
| 地址 | `*_addr_i`, `*_addr_o` |
| 长度 | `*_len_i`, `*_len_o` |
| 完成 | `*_done_i`, `*_done_o` |
| 错误 | `*_err_i`, `*_err_o` |

示例：

```verilog
input  wire [511:0] da_data_i,
input  wire         da_valid_i,
output wire         da_ready_o,
output wire         da_last_o
```

---

## 4. 参数与常量

### 4.1 parameter 命名

模块外部可配置参数使用 `PARM_` 前缀。

```verilog
parameter integer PARM_DATA_WIDTH    = 512,
parameter integer PARM_ADDR_WIDTH   = 32,
parameter integer PARM_BURST_LEN = 16
```

### 4.2 localparam 命名

模块内部常量使用 `LP_` 前缀。

```verilog
localparam integer LPARM_BYTE_WIDTH    = P_DATA_WIDTH / 8;
localparam integer LPARM_CNT_WIDTH     = $clog2(PARM_BURST_LEN + 1);
localparam integer LPARM_ADDR_STEP = LPARM_BYTE_WIDTH;
```

### 4.3 避免魔法数

不在逻辑中直接写无解释常数。

不推荐：

```verilog
addr_r <= addr_r + 64;
```

推荐：

```verilog
addr_r <= addr_r + LPARM_ADDR_STEP;
```

### AXI 协议尺寸对照（并入自 FPGA_RTL_DEBUG_RULES §5）

新增读写引擎必须按此设置 `ARSIZE/AWSIZE`，不得硬编码来历不明的常数：

- **512-bit beat = 64 Byte，`ARSIZE/AWSIZE = 3'b110`**。
- **256-bit beat = 32 Byte，`ARSIZE/AWSIZE = 3'b101`**。
- burst 参数沿用既有范式：`AXI_BURST_SIZE = $clog2(AXI_DWIDTH/8)`、`AXI_BURST_LENGTH = AXI_BURST_TRANSMIT_SIZE/(AXI_DWIDTH/8)`（参见 `ddr3_user_app.v`）；地址步进用 `<< $clog2(...)` 表达，不硬编码移位常数。

---

## 5. 内部信号命名

### 5.1 wire / reg 后缀

推荐后缀：

| 类型 | 后缀 |
|---|---|
| wire | `_w` |
| reg | `_r` |
| next-state / next-value | `_n` |
| delayed 1 cycle | `_d1` |
| delayed 2 cycles | `_d2` |
| synchronized stage 1 | `_sync1` |
| synchronized stage 2 | `_sync2` |

示例：

```verilog
wire        wr_fire_w;
wire        rd_fire_w;

reg  [7:0]  beat_cnt_r;
reg  [7:0]  beat_cnt_n;

reg         start_sync1_r;
reg         start_sync2_r;
```

### 5.2 握手信号

handshake fire 信号统一使用：

```verilog
assign wr_fire_w = wr_valid_i && wr_ready_o;
assign rd_fire_w = rd_valid_o && rd_ready_i;
```

---

## 6. always 块风格

### 6.1 时序 always

统一使用：

```verilog
always @(posedge C_gclk_100M_i) begin
    if (R_gclk_100M_rst_i) begin
        ...
    end
    else begin
        ...
    end
end
```

要求：

- 时序逻辑使用非阻塞赋值 `<=`。
- 一个 always 块只属于一个时钟域。
- reset 分支初始化该 always 块内所有寄存器。
- reset 后的状态必须明确。
- 不在时序 always 中混入无关组合计算。

示例：

```verilog
always @(posedge C_gclk_100M_i) begin
    if (R_gclk_100M_rst_i) begin
        valid_r <= 1'b0;
        data_r  <= {P_DATA_W{1'b0}};
    end
    else begin
        if (load_i) begin
            valid_r <= 1'b1;
            data_r  <= data_i;
        end
        else if (valid_r && ready_i) begin
            valid_r <= 1'b0;
        end
    end
end
```

### 6.2 组合 always

组合逻辑使用：

```verilog
always @(*) begin
    ...
end
```

要求：

- 组合逻辑使用阻塞赋值 `=`。
- 开头给默认值，避免 latch。
- 不在组合 always 中写寄存器更新语义。

示例：

```verilog
always @(*) begin
    state_n = state_r;
    done_n  = 1'b0;

    case (state_r)
        ST_IDLE: begin
            if (start_i) begin
                state_n = ST_RUN;
            end
        end

        ST_RUN: begin
            if (last_fire_w) begin
                state_n = ST_DONE;
            end
        end

        ST_DONE: begin
            done_n  = 1'b1;
            state_n = ST_IDLE;
        end

        default: begin
            state_n = ST_IDLE;
        end
    endcase
end
```

---

## 7. FSM 风格

### 7.1 状态命名

状态机状态使用大写，统一 `ST_` 前缀。

示例：

```verilog
localparam [2:0] ST_IDLE  = 3'd0;
localparam [2:0] ST_INIT  = 3'd1;
localparam [2:0] ST_RUN   = 3'd2;
localparam [2:0] ST_WAIT  = 3'd3;
localparam [2:0] ST_DONE  = 3'd4;
localparam [2:0] ST_ERROR = 3'd5;
```

### 7.2 状态寄存器

状态寄存器使用：

```verilog
reg [2:0] state_r;
reg [2:0] state_n;
```

### 7.3 FSM 结构

推荐三段式：

1. 状态寄存器；
2. 状态转移组合逻辑；
3. 输出/计数器时序逻辑。

示例：

```verilog
// ============================================================
// FSM state register
// ============================================================

always @(posedge C_gclk_100M_i) begin
    if (R_gclk_100M_rst_i) begin
        state_r <= ST_IDLE;
    end
    else begin
        state_r <= state_n;
    end
end

// ============================================================
// FSM next-state logic
// ============================================================

always @(*) begin
    state_n = state_r;

    case (state_r)
        ST_IDLE: begin
            if (start_i) begin
                state_n = ST_RUN;
            end
        end

        ST_RUN: begin
            if (last_fire_w) begin
                state_n = ST_DONE;
            end
        end

        ST_DONE: begin
            state_n = ST_IDLE;
        end

        ST_ERROR: begin
            state_n = ST_ERROR;
        end

        default: begin
            state_n = ST_IDLE;
        end
    endcase
end
```

---

## 8. valid-ready 风格

### 8.1 握手定义

统一使用 fire 信号描述握手成立：

```verilog
assign in_fire_w  = in_valid_i  && in_ready_o;
assign out_fire_w = out_valid_o && out_ready_i;
```

### 8.2 valid 保持

当 `valid_o = 1'b1` 且 `ready_i = 1'b0` 时：

- `valid_o` 必须保持；
- `data_o` 必须保持；
- `last_o` / `keep_o` / `user_o` 等 sideband 必须保持。

示例：

```verilog
always @(posedge C_gclk_100M_i) begin
    if (R_gclk_100M_rst_i) begin
        out_valid_r <= 1'b0;
        out_data_r  <= {P_DATA_W{1'b0}};
    end
    else begin
        if (!out_valid_r || out_ready_i) begin
            out_valid_r <= next_valid_w;
            out_data_r  <= next_data_w;
        end
    end
end

assign out_valid_o = out_valid_r;
assign out_data_o  = out_data_r;
```

### 连续流 underrun / priming 策略（并入自 FPGA_RTL_DEBUG_RULES §7）

DA 类连续消费流（消费端不带 ready 背压）必须显式定义以下策略，不得隐含：

1. **数据与 valid 对齐**：valid=1 时 data 必须有效；没有 valid 语义时不得把 0 默认当有效数据。
2. **underrun 策略**：运行中源 FIFO 空 → 输出 0 或保持上一样点（二选一并注明），同时必须有 **sticky underrun 标志 + 饱和 underrun 计数器**（供 ILA），不得被后续恢复掩盖。
3. **背压**：`prog_full` → 上游读引擎停发请求（正常流控，非错误）。
4. **启动 priming**：FIFO 未达阈值前不放行输出，避免开机 underrun。
5. **FIFO 状态可观测**：`empty/full/prog_empty/prog_full/underflow/overflow` 应引出供 ILA。
6. 长稳验收口径：长时间连续运行 **underrun 计数 = 0**（只证明观察期内无欠载，不证明数据值正确）。

---

## 9. AXI / AXIS 命名

### 9.1 AXI-MM

AXI-MM 信号使用标准通道命名：

```text
awaddr
awvalid
awready
wdata
wstrb
wvalid
wready
bresp
bvalid
bready
araddr
arvalid
arready
rdata
rresp
rvalid
rready
rlast
```

模块端口带方向后缀：

```verilog
output wire [31:0] m_axi_awaddr_o,
output wire        m_axi_awvalid_o,
input  wire        m_axi_awready_i
```

### 9.2 AXIS

AXIS 信号使用标准命名：

```text
tdata
tvalid
tready
tlast
tkeep
tuser
```

输入接口使用 `s_axis_*`，输出接口使用 `m_axis_*`：

```verilog
input  wire [511:0] s_axis_tdata_i,
input  wire         s_axis_tvalid_i,
output wire         s_axis_tready_o,

output wire [511:0] m_axis_tdata_o,
output wire         m_axis_tvalid_o,
input  wire         m_axis_tready_i
```

---

## 10. CDC 基础风格

### 10.1 单 bit 同步

单 bit 控制信号跨时钟域使用至少两级同步器。

```verilog
(* ASYNC_REG = "TRUE" *) reg start_i_r;
(* ASYNC_REG = "TRUE" *) reg start_i_rr;

always @(posedge C_dst_clk_i) begin
    if (R_dst_rst_i) begin
        start_i_r <= 1'b0;
        start_i_rr <= 1'b0;
    end
    else begin
        start_i_r <= start_i;
        start_i_rr <= start_i_r;
    end
end
```

### 10.2 多 bit 数据跨域

多 bit 数据跨域不使用普通多级寄存器直接同步。应使用 async FIFO 或明确的跨域握手结构。

### 10.3 时钟域标注

跨域相关信号命名中应体现源域或目标域：

```verilog
src_start_r
dst_start_sync1_r
dst_start_sync2_r
```

### 10.4 FIFO 计数跨域禁令与时序例外边界（并入自 FPGA_RTL_DEBUG_RULES §6）

1. **FIFO count 不得 wrong-side 跨域**：`wr_data_count` 只能在 `wr_clk` 域用，`rd_data_count` 只能在 `rd_clk` 域用；禁止把一侧 count 跨域当另一侧用。
2. **同步器第一拍例外**：异步输入到第一级同步寄存器允许 `set_false_path`（标准 CDC 约束）；不得当普通同步业务路径，也不得用它掩盖真实同步路径违例。
3. **Inter-Clock violation ≠ 一定是 CDC**：只有确认两钟异步、或确认是同步器第一拍后，才可加时序例外；同步相关时钟之间的真实业务路径必须 meet timing。
4. 复位跨域用同步释放（参见 `reset_sync_block` → `sync_block` + `reset_sync`）。

---

## 11. 模块例化风格

### 11.1 例化命名

例化名使用 lower_snake_case。

如果模块名为 `ddr3_da_read_engine`，例化名可为：

```verilog
ddr3_da_read_engine u_ddr3_da_read_engine (
    ...
);
```

testbench 中 DUT 可使用：

```verilog
dut dut (
    ...
);
```

### 11.2 端口分组

例化时按功能和时钟域分组，并用注释标明。

推荐格式：

```verilog
ddr3_da_read_engine u_ddr3_da_read_engine (
    // ========================================================
    // gclk_100M domain
    // ========================================================
    .C_gclk_100M_i          (C_gclk_100M),
    .R_gclk_100M_rst_i      (R_gclk_100M_rst),

    // ========================================================
    // control
    // ========================================================
    .start_i                (da_start_w),
    .done_o                 (da_done_w),
    .err_o                  (da_err_w),

    // ========================================================
    // DDR3 read command
    // ========================================================
    .rd_addr_o              (ddr3_rd_addr_w),
    .rd_len_o               (ddr3_rd_len_w),
    .rd_valid_o             (ddr3_rd_valid_w),
    .rd_ready_i             (ddr3_rd_ready_w),

    // ========================================================
    // DDR3 read data
    // ========================================================
    .rd_data_i              (ddr3_rd_data_w),
    .rd_data_valid_i        (ddr3_rd_data_valid_w),
    .rd_data_ready_o        (ddr3_rd_data_ready_w),
    .rd_last_i              (ddr3_rd_last_w),

    // ========================================================
    // DA stream output
    // ========================================================
    .da_data_o              (da_data_w),
    .da_valid_o             (da_valid_w),
    .da_ready_i             (da_ready_w)
);
```

### 11.3 对齐规则

- 端口名左侧按最长端口对齐。
- 括号内连接信号按列对齐。
- 每个端口一行。
- 最后一个端口后不加逗号。

---

## 12. 模块模板

新增普通 RTL 模块推荐使用以下结构：

```verilog
`timescale 1ns / 1ps

module module_name #(
    parameter integer PARM_DATA_WIDTH = 512,
    parameter integer PARM_ADDR_WIDTH = 32
)(
    // ========================================================
    // Clock and reset
    // ========================================================
    input  wire                  C_gclk_100M_i,
    input  wire                  R_gclk_100M_rst_i,

    // ========================================================
    // Control
    // ========================================================
    input  wire                  start_i,
    output wire                  done_o,
    output wire                  err_o,

    // ========================================================
    // Input stream
    // ========================================================
    input  wire [P_DATA_W-1:0]   s_data_i,
    input  wire                  s_valid_i,
    output wire                  s_ready_o,

    // ========================================================
    // Output stream
    // ========================================================
    output wire [P_DATA_W-1:0]   m_data_o,
    output wire                  m_valid_o,
    input  wire                  m_ready_i
);

// ============================================================
// Local parameter
// ============================================================

localparam integer LP_BYTE_W = P_DATA_W / 8;

// ============================================================
// Internal signal
// ============================================================

wire in_fire_w;
wire out_fire_w;

reg done_r;
reg err_r;

// ============================================================
// Handshake
// ============================================================

assign in_fire_w  = s_valid_i && s_ready_o;
assign out_fire_w = m_valid_o && m_ready_i;

// ============================================================
// Sequential logic
// ============================================================

always @(posedge C_gclk_100M_i) begin
    if (R_gclk_100M_rst_i) begin
        done_r <= 1'b0;
        err_r  <= 1'b0;
    end
    else begin
        done_r <= 1'b0;

        if (out_fire_w) begin
            done_r <= 1'b1;
        end
    end
end

// ============================================================
// Output assignment
// ============================================================

assign done_o = done_r;
assign err_o  = err_r;

endmodule
```

---

## 13. 不推荐写法

### 13.1 不推荐：端口无方向后缀

```verilog
input wire start,
output wire done
```

推荐：

```verilog
input  wire start_i,
output wire done_o
```

### 13.2 不推荐：状态名不统一

```verilog
localparam idle = 0;
localparam Run  = 1;
localparam done = 2;
```

推荐：

```verilog
localparam [1:0] ST_IDLE = 2'd0;
localparam [1:0] ST_RUN  = 2'd1;
localparam [1:0] ST_DONE = 2'd2;
```

### 13.3 不推荐：握手条件散落

```verilog
if (valid && ready) begin
    ...
end
```

推荐：

```verilog
assign data_fire_w = data_valid_i && data_ready_o;

always @(posedge C_gclk_100M_i) begin
    if (R_gclk_100M_rst_i) begin
        ...
    end
    else begin
        if (data_fire_w) begin
            ...
        end
    end
end
```

### 13.4 不推荐：魔法数

```verilog
addr_r <= addr_r + 64;
```

推荐：

```verilog
localparam integer LP_BEAT_BYTE_W = P_DATA_W / 8;

addr_r <= addr_r + LP_BEAT_BYTE_W;
```

---

## 14. 旧代码兼容

- 已存在且已验证的模块不因为本规范进行批量风格化修改。
- 与 legacy 顶层、IP wrapper、脚本依赖端口连接时，保持原端口语义。
- 新增 wrapper/glue logic 可在外层采用本规范，并在连接旧模块时保持清晰映射。
- 对外接口命名优先保证兼容性；内部新增逻辑优先保证风格一致性。
