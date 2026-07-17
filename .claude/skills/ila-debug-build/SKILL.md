---
name: ila-debug-build
description: 新增或修改 ILA Tcl debug 插桩、调整 probe、维护 ENABLE_DEBUG debug build 时使用。生成低侵入、可关闭、单 ILA、单时钟域、probe 分组清晰的 ILA debug 插桩。
---

# ILA Debug Build

## 目标

维护 `tcl/debug/ila_*.tcl`，使 ILA debug 插桩具备：

1. 可单独开启或关闭。
2. 一个文件只创建一个 ILA core。
3. 一个 ILA core 只使用一个 sample clock。
4. 文件头说明 core、clock、purpose、scope 和 probe policy。
5. probe 优先选择控制、状态、计数、错误类信号。
6. data probe 优先采必要 slice。
7. probe 连接区域短注释、分组清晰、index 可审查。
8. net 绑定失败时 WARN-skip。

## 工作顺序

新增或修改 `ila_*.tcl` 时按以下顺序处理：

1. 确认 ILA core name。
2. 确认 sample clock。
3. 添加或保留 `ENABLE_THIS_DEBUG` 局部开关。
4. 保持 one ILA per file。
5. 编写文件头 note block。
6. 按 probe 优先级选择信号。
7. 按信号组连接 probe。
8. 检查 data probe 是否为必要 slice。
9. 检查 net 绑定失败是否 WARN-skip。
10. 在报告中说明该 ILA 属于 debug build 观测逻辑。

## 文件结构模板

```tcl
#########################
#
# note:
# - core: ila_XX_xxx
# - sample_clk: <clock_name>
# - purpose: <本 ILA 用来观察/证明什么>
# - scope: <观测范围>
# - probe policy: valid/ready/state/addr/count/error first; avoid full-width data
# - large probe: none / <signal slice and reason>
# - timing role: debug build only
#
#########################

set ENABLE_THIS_DEBUG 1

if {!$ENABLE_THIS_DEBUG} {
    puts "INFO: skip this ILA because ENABLE_THIS_DEBUG=0"
    return
}

set core_name ila_XX_xxx

# create core / configure core
# ...

# AXI AR channel
dbg_connect_marked_probe $core_name 0 {*xxx_arvalid*} xxx_arvalid
dbg_connect_marked_probe $core_name 1 {*xxx_arready*} xxx_arready
dbg_connect_marked_probe $core_name 2 {*xxx_araddr*}  xxx_araddr

# AXI R channel
dbg_connect_marked_probe $core_name 3 {*xxx_rvalid*} xxx_rvalid
dbg_connect_marked_probe $core_name 4 {*xxx_rready*} xxx_rready
dbg_connect_marked_probe $core_name 5 {*xxx_rlast*}  xxx_rlast

# state / progress
dbg_connect_marked_probe $core_name 6 {*xxx_state*}      xxx_state
dbg_connect_marked_probe $core_name 7 {*xxx_beat_count*} xxx_beat_count
dbg_connect_marked_probe $core_name 8 {*xxx_done*}       xxx_done
```

## 局部开关

每个 ILA Tcl 文件使用固定局部开关：

```tcl
set ENABLE_THIS_DEBUG 1

if {!$ENABLE_THIS_DEBUG} {
    puts "INFO: skip this ILA because ENABLE_THIS_DEBUG=0"
    return
}
```

约定：

- `ENABLE_DEBUG=1` 控制是否进入 debug build。
- `ENABLE_THIS_DEBUG=1` 表示当前 ILA 文件启用。
- `ENABLE_THIS_DEBUG=0` 表示当前 ILA 文件跳过。

## ILA 组织

每个 `ila_*.tcl` 文件只创建一个 ILA core。

文件名与 core name 保持一致或强相关：

```text
tcl/debug/ila_07_ddr3_read_engine.tcl
core_name = ila_07_ddr3_read_engine
```

每个 ILA core 只使用一个 sample clock，并在文件头写明：

```text
# - sample_clk: mig_ddr3_clk
```

## probe 选择优先级

probe 选择按以下优先级处理：

```text
valid / ready / last
> state / FSM
> addr / len / size / burst
> beat count / burst count / packet count
> FIFO level / empty / full
> underflow / overflow / error
> mux select / arm / trigger / done
> data slice
> full-width data bus
```

data probe 使用原则：

1. 优先采 32b / 64b slice。
2. 采 data 时，在文件头说明用途。
3. 采完整 256b / 512b / 1024b data bus 时，在文件头说明必须采完整总线的原因。

## probe 连接风格

probe 连接区域使用短分组注释：

```tcl
# engine AXI AR channel
dbg_connect_marked_probe $core_name 0 {*eng_arvalid*} eng_arvalid
dbg_connect_marked_probe $core_name 1 {*eng_arready*} eng_arready
dbg_connect_marked_probe $core_name 2 {*eng_araddr*}  eng_araddr

# engine AXI R channel
dbg_connect_marked_probe $core_name 3 {*eng_rvalid*} eng_rvalid
dbg_connect_marked_probe $core_name 4 {*eng_rready*} eng_rready
dbg_connect_marked_probe $core_name 5 {*eng_rlast*}  eng_rlast

# FIFO status
dbg_connect_marked_probe $core_name 6 {*fifo_rd_count*}  fifo_rd_count
dbg_connect_marked_probe $core_name 7 {*fifo_empty*}     fifo_empty
dbg_connect_marked_probe $core_name 8 {*fifo_underflow*} fifo_underflow
```

要求：

1. 同组 probe 连续排列。
2. 不同组之间空行分隔。
3. 注释只写组名或短说明。
4. 长解释放到文件头。
5. label 使用 RTL 语义名。
6. index 连续或按组可审查。

## 跨时钟 probe

ILA 采样信号应属于 ILA sample clock 所在时钟域。

需要观测其他时钟域信号时，使用 debug register 同步到 sample clock 域：

```verilog
(* mark_debug = "true" *) reg dbg_xxx_sync_d1;
(* mark_debug = "true" *) reg dbg_xxx_sync_d2;

always @(posedge sample_clk) begin
    dbg_xxx_sync_d1 <= xxx_async;
    dbg_xxx_sync_d2 <= dbg_xxx_sync_d1;
end
```

ILA 连接同步后的 debug register：

```tcl
dbg_connect_marked_probe $core_name 10 {*dbg_xxx_sync_d2*} dbg_xxx_sync_d2
```

## net 绑定

probe 绑定优先级：

1. 顶层 debug net。
2. 已加 `mark_debug` 且命名稳定的 net。
3. RTL 中专门增加的 debug register。
4. 已验证可稳定命中的 pattern fallback。

绑定结果处理：

```text
matched one stable net -> connect
matched none -> WARN-skip
matched multiple ambiguous nets -> WARN-skip
```

推荐提示：

```tcl
puts "WARN: skip probe <name>, no matched debug net"
```

## 提交前检查

1. 有 note block。
2. 有 `ENABLE_THIS_DEBUG`。
3. `ENABLE_THIS_DEBUG=0` 时安全 return。
4. one ILA per file。
5. one sample clock per ILA。
6. probe 按组排列。
7. probe label 语义明确。
8. probe index 可审查。
9. data probe 优先使用 slice。
10. 大位宽 data probe 在文件头说明原因。
11. 跨时钟 probe 同步到 sample clock 域。
12. net 绑定失败 WARN-skip。