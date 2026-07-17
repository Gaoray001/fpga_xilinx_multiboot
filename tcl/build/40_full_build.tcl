####################################################################
# 功能: 执行从项目初始化到bit流生成的完整构建流程，并记录构建摘要
# 依赖: 需要 common_utils.tcl 中定义的函数来管理构建流程和报告
####################################################################

# 获取当前脚本所在的绝对路径目录
# 分解步骤：
#   info script              -> 获取当前脚本路径（可能是相对路径）
#   file normalize           -> 转换为绝对路径并解析符号链接
#   file dirname             -> 提取目录部分
# SCRIPT_DIR --> <project_root>/tcl/build
set SCRIPT_DIR [file dirname [file normalize [info script]]]
# 把 common_utils.tcl 所在目录加入 source 搜索路径
source [file join $SCRIPT_DIR "common_utils.tcl"]

# ====================== 2. 构建环境准备 ======================

# 创建本次构建的阶段目录（用于存放所有输出文件）
# 参数 "full_build" 表示本次构建的名称
# 返回：创建的目录路径，例如：./build/full_build_20250101_120000
set STAGE_DIR [common_make_stage_dir  "full_build"]

# 定义构建摘要文件的完整路径
# 该文件将记录整个构建过程的关键信息
set BUILD_SUMMARY [file join $STAGE_DIR "build_summary.txt"]
# 获取构建开始时间（格式：YYYY-MM-DD HH:MM:SS）
set START_TIME [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
# 以追加模式打开构建摘要文件
# "a" 表示 append，如果文件存在则追加，不存在则创建
set fp [open $BUILD_SUMMARY a]
puts $fp "command: full_build"  
puts $fp "root: [common_root_dir]"
puts $fp "started: $START_TIME"
close $fp

# ====================== 3. FPGA 构建核心流程 ======================

# 如果工程已存在则打开，否则创建新工程
common_open_or_rebuild_project

# 运行综合（Synthesis）参数1: STAGE_DIR - 输出目录 参数2: 1 - 启用详细日志输出
common_run_synth $STAGE_DIR 1

# 导出综合阶段的报告（时序、资源利用率等）
common_export_synth_reports $STAGE_DIR

# 根据环境变量调度临时 debug 插入，默认关闭
common_debug_insertions $STAGE_DIR 1

# 运行实现（Implementation），包含布局布线 
# 参数1: STAGE_DIR - 输出目录
# 参数2: 1 - 启用详细日志输出
# 参数3: "write_bitstream" - 生成比特流文件
common_run_impl $STAGE_DIR 1 "write_bitstream"

# 导出实现阶段的报告（时序收敛、资源使用等）
common_export_impl_reports $STAGE_DIR

# 复制运行日志到统一的输出目录
common_copy_run_logs

# ====================== 4. 结果验证与错误处理 ======================

# 查找生成的比特流文件
# 返回：比特流文件路径列表（可能有多个，如 .bit 和 .bin）
set bit_files [common_find_bit_files]

# 以追加模式重新打开摘要文件
set fp [open $BUILD_SUMMARY a]

# 记录综合和实现的运行状态
# common_run_status 返回每个阶段的完成状态（成功/失败）
puts $fp "synth_1 status: [common_run_status synth_1]"
puts $fp "impl_1 status: [common_run_status impl_1]"

# 检查是否成功生成比特流文件
# llength 返回列表长度，为 0 表示没有找到任何比特流文件
if {[llength $bit_files] == 0} {
    common_write_tcl_status 0
    puts $fp "ERROR: no bitstream found under work/Prj_work/Prj.runs/impl_1"
    close $fp
    error "No bitstream found under work/Prj_work/Prj.runs/impl_1"
}

# ====================== 5. 记录构建结果 ======================
# 遍历所有找到的比特流文件并记录到摘要
foreach bit_file $bit_files {
    puts $fp "bitstream: $bit_file"
}
set artifact_count [common_copy_artifacts]
puts $fp "artifacts_copied: $artifact_count"
common_write_tcl_status 1
set FINISH_TIME [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
puts $fp "finished: $FINISH_TIME"
close $fp

# ====================== 6. 汇总输出与完成通知 ======================

# 将摘要文件路径追加到阶段目录的总体摘要中
# 用于在多层构建中汇总所有子构建的信息
common_append_summary $STAGE_DIR "build_summary: $BUILD_SUMMARY"

# 标记当前阶段完成
common_append_summary $STAGE_DIR "done: full_build"

# 向控制台输出成功信息
puts "INFO: Full build finished."

# 提示用户查看详细摘要文件的位置
puts "INFO: Build summary: $BUILD_SUMMARY"
