######################################################################################
# 01_create_project.tcl  (TEMPLATE — generic, cross-project version)
#
# 来源: 从 dspboard 工程实测跑通的 tcl/build/01_create_project.tcl 抽取通用骨架，
#       移除了 dspboard 专属硬编码（JamPro EDIF 网表路径 / systemHeader.sv 排除名 /
#       DSPBOARD_ 前缀环境变量），改为可配置项，供任意新工程直接使用或按需精简。
#
# 功能: 从源码装配出当前 run 的 Vivado 工程。
#       工程生成在 _runs/common_vivado/<stamp>_<cmd>/work/Prj_work/ 下，
#       不在 Git 工程根目录维护固定 Prj/ 模板工程。
#
# 装配内容:
#   - create_project (part 必须由 COMMON_VIVADO_PART_NAME 指定，无内置默认器件)
#   - 递归导入 rtl/hdl/ 下的 .v/.sv/.vhd（排除 "* copy*" 冗余副本 + 可选排除名单）
#   - 逐个 source tcl/ip/*.tcl 重建 Xilinx IP 定义（新工程该目录为空时此步为空操作）
#   - 可选 read_edif 导入第三方网表（未设置 COMMON_VIVADO_EDIF_FILE 时跳过，不报警）
#   - 导入顶层 XDC 约束（若 constraints/ 下存在）
#   - 设置 top，更新编译顺序，生成 work/Prj_work/Prj.xpr
#
# 环境变量:
#   COMMON_VIVADO_ROOT_DIR   : 工程根目录（由 vivado2018_common.sh 导出；缺省时自动推导）
#   COMMON_VIVADO_PART_NAME  : 器件型号，必须设置，无内置默认值（避免误用其它工程的器件）
#   COMMON_VIVADO_TOP_MODULE : 顶层模块，默认 Top
#   COMMON_VIVADO_EDIF_FILE  : 第三方 EDIF 网表绝对/相对路径，可选；未设置则跳过 read_edif
#   COMMON_VIVADO_INCLUDE_DIR: Verilog `include 搜索目录，默认 rtl/hdl/user（不存在则跳过）
#   COMMON_VIVADO_RTL_EXCLUDE_NAMES: 逗号分隔的额外排除文件名（精确匹配 tail），可选
#   COMMON_VIVADO_SKIP_IP_GEN=1 : 跳过 generate_target（仅创建 IP 定义，加快装配/冒烟测试）
#
# 说明: 本脚本不修改任何 RTL/XDC，只做工程装配。
#
# 新工程接入清单（对照 dspboard reports/claude/002_changes_and_reuse_guide.md B.1）:
#   [ ] 设置 COMMON_VIVADO_PART_NAME（必须，无默认值会直接 error）
#   [ ] 确认 COMMON_VIVADO_TOP_MODULE 是否用默认 "Top"
#   [ ] rtl/hdl/** 放入本工程 RTL
#   [ ] tcl/ip/*.tcl 放入本工程 write_ip_tcl 导出的 IP 脚本（可为空，允许工程无 IP）
#   [ ] constraints/*.xdc 放入本工程顶层约束
#   [ ] 如有第三方 EDIF 网表，设置 COMMON_VIVADO_EDIF_FILE；否则忽略
#   [ ] 如有需要排除出综合的 include-only 头文件，设置 COMMON_VIVADO_RTL_EXCLUDE_NAMES
######################################################################################

set SCRIPT_DIR [file dirname [file normalize [info script]]]
source [file join $SCRIPT_DIR "common_utils.tcl"]

set ROOT_DIR [common_root_dir]

if {![info exists ::env(COMMON_VIVADO_PART_NAME)] || $::env(COMMON_VIVADO_PART_NAME) eq ""} {
    error "COMMON_VIVADO_PART_NAME is not set. This template has no built-in default part;\
set it explicitly, e.g. COMMON_VIVADO_PART_NAME=xc7vx690tffg1927-2 ./scripts/vivado2018_common.sh create"
}
set PART $::env(COMMON_VIVADO_PART_NAME)

set TOP_MODULE "Top"
if {[info exists ::env(COMMON_VIVADO_TOP_MODULE)] && $::env(COMMON_VIVADO_TOP_MODULE) ne ""} {
    set TOP_MODULE $::env(COMMON_VIVADO_TOP_MODULE)
}

set PROJ_NAME "Prj"
set PROJ_DIR  [common_project_work_dir]
set RTL_DIR   [file join $ROOT_DIR "rtl" "hdl"]
set IP_DIR    [file join $ROOT_DIR "tcl" "ip"]

set EDIF_FILE ""
if {[info exists ::env(COMMON_VIVADO_EDIF_FILE)] && $::env(COMMON_VIVADO_EDIF_FILE) ne ""} {
    set EDIF_FILE $::env(COMMON_VIVADO_EDIF_FILE)
    if {![string match "/*" $EDIF_FILE]} {
        set EDIF_FILE [file join $ROOT_DIR $EDIF_FILE]
    }
}

set RTL_EXCLUDE_NAMES {}
if {[info exists ::env(COMMON_VIVADO_RTL_EXCLUDE_NAMES)] && $::env(COMMON_VIVADO_RTL_EXCLUDE_NAMES) ne ""} {
    foreach n [split $::env(COMMON_VIVADO_RTL_EXCLUDE_NAMES) ","] {
        lappend RTL_EXCLUDE_NAMES [string trim $n]
    }
}

puts "INFO: 01_create_project: ROOT_DIR = $ROOT_DIR"
puts "INFO: 01_create_project: PART     = $PART"
puts "INFO: 01_create_project: TOP      = $TOP_MODULE"
puts "INFO: 01_create_project: PROJ_DIR = $PROJ_DIR"

######################################################################################
# 1. 关闭已打开的工程，创建当前 run 的隔离工程
######################################################################################
if {[current_project -quiet] ne ""} {
    puts "INFO: Closing currently open project: [current_project]"
    close_project
}
create_project $PROJ_NAME $PROJ_DIR -part $PART -force
set_property target_language Verilog [current_project]
set_property simulator_language Mixed  [current_project]
set_property default_lib xil_defaultlib [current_project]

######################################################################################
# 2. 递归收集 RTL 源文件（.v/.sv/.vhd）
#    - 跳过文件名含 " copy" 的冗余副本（通用防呆规则，适用任何工程）
#    - 跳过 COMMON_VIVADO_RTL_EXCLUDE_NAMES 列出的 include-only 头文件（如有）
######################################################################################
proc collect_rtl_files {dir exclude_names} {
    set result {}
    foreach item [glob -nocomplain -directory $dir *] {
        if {[file isdirectory $item]} {
            set result [concat $result [collect_rtl_files $item $exclude_names]]
        } else {
            set ext  [string tolower [file extension $item]]
            set name [file tail $item]
            if {[string match "* copy*" $name]} { continue }
            if {[lsearch -exact $exclude_names $name] >= 0} { continue }
            if {$ext eq ".v" || $ext eq ".sv" || $ext eq ".vhd" || $ext eq ".edf"} {
                lappend result [file normalize $item]
            }
        }
    }
    return $result
}

set rtl_files [collect_rtl_files $RTL_DIR $RTL_EXCLUDE_NAMES]
if {[llength $rtl_files] == 0} {
    error "No RTL files found under $RTL_DIR"
}
puts "INFO: Adding [llength $rtl_files] RTL files"
add_files -norecurse -fileset sources_1 $rtl_files

# `include 搜索目录：默认 rtl/hdl/user，可用 COMMON_VIVADO_INCLUDE_DIR 覆盖；目录不存在则跳过
set inc_dir [file join $RTL_DIR "user"]
if {[info exists ::env(COMMON_VIVADO_INCLUDE_DIR)] && $::env(COMMON_VIVADO_INCLUDE_DIR) ne ""} {
    set inc_dir $::env(COMMON_VIVADO_INCLUDE_DIR)
    if {![string match "/*" $inc_dir]} {
        set inc_dir [file join $ROOT_DIR $inc_dir]
    }
}
if {[file isdirectory $inc_dir]} {
    set_property include_dirs [list $inc_dir] [get_filesets sources_1]
    puts "INFO: include_dirs = $inc_dir"
} else {
    puts "INFO: include_dirs skipped, directory does not exist: $inc_dir"
}

######################################################################################
# 3. 重建 Xilinx IP 定义（逐个 source tcl/ip/*.tcl）
#    每个 IP 脚本在工程已打开时只执行 create_ip，不会再 create_project。
#    新工程 tcl/ip/ 为空目录时，本节自然是空操作，不报错。
######################################################################################
set ip_tcls [lsort [glob -nocomplain [file join $IP_DIR "*.tcl"]]]
puts "INFO: Sourcing [llength $ip_tcls] IP build scripts"
foreach ip_tcl $ip_tcls {
    puts "INFO:   create IP <- [file tail $ip_tcl]"
    if {[catch {source $ip_tcl} err]} {
        puts "WARN: IP script failed: [file tail $ip_tcl] : $err"
    }
}

# 生成 IP 输出产物（综合前必须；可用 COMMON_VIVADO_SKIP_IP_GEN=1 跳过以加快装配）
set skip_ip_gen 0
if {[info exists ::env(COMMON_VIVADO_SKIP_IP_GEN)] && $::env(COMMON_VIVADO_SKIP_IP_GEN) eq "1"} {
    set skip_ip_gen 1
}
set all_ips [get_ips -quiet]
if {$skip_ip_gen} {
    puts "INFO: COMMON_VIVADO_SKIP_IP_GEN=1 -> skip generate_target ([llength $all_ips] IPs defined)"
} elseif {[llength $all_ips] > 0} {
    puts "INFO: generate_target for [llength $all_ips] IPs"
    generate_target all $all_ips
}

######################################################################################
# 4. 可选：导入第三方 EDIF 网表（未设置 COMMON_VIVADO_EDIF_FILE 时跳过，不报警）
######################################################################################
if {$EDIF_FILE ne ""} {
    if {[file exists $EDIF_FILE]} {
        puts "INFO: read_edif $EDIF_FILE"
        if {[catch {read_edif $EDIF_FILE} err]} {
            puts "WARN: read_edif failed: $err"
        }
    } else {
        puts "WARN: COMMON_VIVADO_EDIF_FILE set but not found: $EDIF_FILE"
    }
} else {
    puts "INFO: COMMON_VIVADO_EDIF_FILE not set, skipping read_edif."
}

######################################################################################
# 5. 导入顶层 XDC 约束（若存在）
######################################################################################
set xdc_files {}
foreach pat [list \
        [file join $ROOT_DIR "constraints" "*.xdc"] \
        [file join $ROOT_DIR "constraints" "**" "*.xdc"] \
        [file join $ROOT_DIR "rtl" "**" "*.xdc"]] {
    foreach f [glob -nocomplain $pat] { lappend xdc_files [file normalize $f] }
}
set xdc_files [lsort -unique $xdc_files]
if {[llength $xdc_files] > 0} {
    puts "INFO: Adding [llength $xdc_files] XDC constraint files"
    add_files -fileset constrs_1 $xdc_files
} else {
    puts "WARN: No .xdc constraints found under constraints/ or rtl/."
    puts "WARN: Implementation will be unconstrained (no pin/clock constraints)."
    puts "WARN: Provide top-level XDC before running impl/bit."
}

######################################################################################
# 6. 设定顶层、更新编译顺序、保存工程
######################################################################################
set_property top $TOP_MODULE [current_fileset]
common_update_compile_order

puts "INFO: project        = [current_project]"
puts "INFO: project_dir    = [get_property DIRECTORY [current_project]]"
puts "INFO: part           = [get_property PART [current_project]]"
puts "INFO: top            = [get_property top [current_fileset]]"
puts "INFO: source files   = [llength [get_files -quiet -of_objects [get_filesets sources_1]]]"
puts "INFO: ip count       = [llength [get_ips -quiet]]"

common_export_project_reports [common_reports_dir]

# 工程模式下 create_project/add_files/create_ip 会即时写入 .xpr，无需显式 save。
puts "INFO: 01_create_project finished. Project: [file join $PROJ_DIR ${PROJ_NAME}.xpr]"
