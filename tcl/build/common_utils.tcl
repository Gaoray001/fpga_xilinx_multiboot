# Common helpers for Vivado 2018.3 project-mode batch scripts.
#
# 本文件集中封装 Vivado batch 构建脚本的公共逻辑，包括:
#   - 定位工程根目录和本次运行目录
#   - 创建 reports/artifacts/logs/work 等输出目录
#   - 打开或生成隔离的 Vivado 工程副本
#   - 运行 synth_1/impl_1 并导出常用报告
#   - 通过 COMMON_VIVADO_JOBS 控制 Vivado 编译线程/作业数
#   - 按环境变量控制 debug Tcl 插入
#   - 收集 bit/ltx/dcp/xsa/hwh 产物和 runme.log
#
# Tcl 新手阅读提示:
#   - proc name {args} {body} 定义函数。
#   - [cmd arg] 会先执行 cmd，并把返回值替换到当前位置。
#   - $var 读取变量，::env(NAME) 读取环境变量 NAME。
#   - {a b c} 常用来写列表或延迟变量替换。
#   - catch { ... } err 捕获错误，失败时返回非 0，错误信息放入 err。
#   - Vivado 命令如 get_runs/open_project/launch_runs 只能在 Vivado Tcl 环境中执行。

################################################################################
# 函数: common_script_dir
# 作用: 返回当前 common_utils.tcl 所在目录的绝对路径。
# 参数: 无。
# 返回: 目录路径，例如 /home/user/project/tcl/build。
# 内部逻辑:
#   1. info script 得到当前被 source 的脚本路径。
#   2. file normalize 把相对路径转换成规范化绝对路径。
#   3. file dirname 取出文件所在目录。
################################################################################
proc common_script_dir {} {
    return [file dirname [file normalize [info script]]]
}

################################################################################
# 函数: common_root_dir
# 作用: 返回 FPGA 工程根目录。
# 参数: 无。
# 返回: 工程根目录绝对路径。
# 内部逻辑:
#   1. 如果 COMMON_VIVADO_ROOT_DIR 已设置且非空，优先使用环境变量。
#   2. 否则从 tcl/build 目录向上两级，推导出仓库/工程根目录。
################################################################################
proc common_root_dir {} {
    if {[info exists ::env(COMMON_VIVADO_ROOT_DIR)] && $::env(COMMON_VIVADO_ROOT_DIR) ne ""} {
        return $::env(COMMON_VIVADO_ROOT_DIR)
    }
    return [file dirname [file dirname [common_script_dir]]]
}

################################################################################
# 函数: common_project_name
# 作用: 返回 Vivado 工程名。
# 参数: 无。
# 返回: 工程名字符串。
# 内部逻辑:
#   1. 如果 COMMON_VIVADO_PROJECT_NAME 已设置且非空，直接返回它。
#   2. 否则使用工程根目录的最后一级目录名作为默认工程名。
################################################################################
proc common_project_name {} {
    if {[info exists ::env(COMMON_VIVADO_PROJECT_NAME)] && $::env(COMMON_VIVADO_PROJECT_NAME) ne ""} {
        return $::env(COMMON_VIVADO_PROJECT_NAME)
    }
    return [file tail [common_root_dir]]
}

################################################################################
# 函数: common_timestamp
# 作用: 生成用于目录名/文件名的时间戳。
# 参数: 无。
# 返回: 格式为 YYYYMMDD_HHMMSS 的字符串，例如 20240601_153045。
# 内部逻辑:
#   1. clock seconds 取得当前 Unix 时间。
#   2. clock format 按指定格式转成可读字符串。
################################################################################
proc common_timestamp {} {
    return [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
}

################################################################################
# 函数: common_run_root
# 作用: 返回本次构建的顶层运行目录。
# 参数: 无。
# 返回: 运行目录路径。
# 内部逻辑:
#   1. 如果 COMMON_VIVADO_RUN_DIR 已设置且非空，使用该目录。
#   2. 否则使用 <root>/_runs/common_vivado/<timestamp>。
# 注意:
#   这个函数每次调用都会在默认路径里重新计算时间戳；调用者如需固定目录，
#   应通过 COMMON_VIVADO_RUN_DIR 固定，或确保脚本流程中不会跨秒反复求值。
################################################################################
proc common_run_root {} {
    set root_dir [common_root_dir]
    if {[info exists ::env(COMMON_VIVADO_RUN_DIR)] && $::env(COMMON_VIVADO_RUN_DIR) ne ""} {
        return $::env(COMMON_VIVADO_RUN_DIR)
    }
    return [file normalize [file join $root_dir "_runs" "common_vivado" [common_timestamp]]]
}

################################################################################
# 函数: common_env_dir
# 作用: 根据环境变量或默认名称创建并返回一个输出目录。
# 参数:
#   env_name      环境变量名，例如 COMMON_VIVADO_REPORTS_DIR。
#   fallback_name 环境变量未设置时，挂在 common_run_root 下的默认子目录名。
# 返回: 已创建的目录路径。
# 内部逻辑:
#   1. 检查 ::env($env_name) 是否存在且非空。
#   2. 存在时使用环境变量路径；否则使用 <run_root>/<fallback_name>。
#   3. file mkdir 创建目录，目录已存在也不会报错。
################################################################################
proc common_env_dir {env_name fallback_name} {
    if {[info exists ::env($env_name)] && $::env($env_name) ne ""} {
        set dir $::env($env_name)
    } else {
        set dir [file join [common_run_root] $fallback_name]
    }
    file mkdir $dir
    return $dir
}

################################################################################
# 函数: common_reports_dir
# 作用: 返回报告目录，必要时创建。
# 参数: 无。
# 返回: reports 目录路径。
# 内部逻辑: 优先使用 COMMON_VIVADO_REPORTS_DIR，否则使用 <run_root>/reports。
################################################################################
proc common_reports_dir {} {
    return [common_env_dir "COMMON_VIVADO_REPORTS_DIR" "reports"]
}

################################################################################
# 函数: common_artifacts_dir
# 作用: 返回构建产物目录，必要时创建。
# 参数: 无。
# 返回: artifacts 目录路径。
# 内部逻辑: 优先使用 COMMON_VIVADO_ARTIFACTS_DIR，否则使用 <run_root>/artifacts。
################################################################################
proc common_artifacts_dir {} {
    return [common_env_dir "COMMON_VIVADO_ARTIFACTS_DIR" "artifacts"]
}

################################################################################
# 函数: common_logs_dir
# 作用: 返回日志目录，必要时创建。
# 参数: 无。
# 返回: logs 目录路径。
# 内部逻辑: 优先使用 COMMON_VIVADO_LOGS_DIR，否则使用 <run_root>/logs。
################################################################################
proc common_logs_dir {} {
    return [common_env_dir "COMMON_VIVADO_LOGS_DIR" "logs"]
}

################################################################################
# 函数: common_work_dir
# 作用: 返回临时工作目录，必要时创建。
# 参数: 无。
# 返回: work 目录路径。
# 内部逻辑: 优先使用 COMMON_VIVADO_WORK_DIR，否则使用 <run_root>/work。
################################################################################
proc common_work_dir {} {
    return [common_env_dir "COMMON_VIVADO_WORK_DIR" "work"]
}

################################################################################
# 函数: common_detect_cpu_count
# 作用: 尝试检测当前机器可用 CPU 线程数。
# 参数: 无。
# 返回: 检测成功返回正整数；检测失败返回空字符串。
# 内部逻辑:
#   1. 优先执行 Linux 常见命令 nproc。
#   2. 如果 nproc 不可用，再尝试 getconf _NPROCESSORS_ONLN。
#   3. 两者都失败时返回空字符串，由调用者决定如何处理。
################################################################################
proc common_detect_cpu_count {} {
    if {![catch {exec nproc} output]} {
        set output [string trim $output]
        if {[string is integer -strict $output]} {
            scan $output "%d" cpu_count
            if {$cpu_count > 0} {
                return $cpu_count
            }
        }
    }

    if {![catch {exec getconf _NPROCESSORS_ONLN} output]} {
        set output [string trim $output]
        if {[string is integer -strict $output]} {
            scan $output "%d" cpu_count
            if {$cpu_count > 0} {
                return $cpu_count
            }
        }
    }

    return ""
}

################################################################################
# 函数: common_vivado_jobs
# 作用: 解析 Vivado 编译线程/作业数设置。
# 参数: 无。
# 返回:
#   - COMMON_VIVADO_JOBS 未设置或为空时返回空字符串，表示使用 Vivado 默认值。
#   - COMMON_VIVADO_JOBS 为正整数时返回该整数。
#   - COMMON_VIVADO_JOBS 为 all/auto/full/max 时返回检测到的 CPU 线程数。
# 内部逻辑:
#   1. 从环境变量 ::env(COMMON_VIVADO_JOBS) 读取用户设置。
#   2. 支持大小写不敏感的 all/auto/full/max，方便临时启用满线程。
#   3. 对非法值直接 error，避免静默使用错误配置。
################################################################################
proc common_vivado_jobs {} {
    if {![info exists ::env(COMMON_VIVADO_JOBS)] || $::env(COMMON_VIVADO_JOBS) eq ""} {
        return ""
    }

    set jobs_text [string trim $::env(COMMON_VIVADO_JOBS)]
    set jobs_key [string tolower $jobs_text]
    if {$jobs_key eq "all" || $jobs_key eq "auto" || $jobs_key eq "full" || $jobs_key eq "max"} {
        set cpu_count [common_detect_cpu_count]
        if {$cpu_count eq ""} {
            error "COMMON_VIVADO_JOBS=$jobs_text but CPU count could not be detected; set COMMON_VIVADO_JOBS to a positive integer"
        }
        return $cpu_count
    }

    if {![string is integer -strict $jobs_text]} {
        error "COMMON_VIVADO_JOBS must be a positive integer or one of: all, auto, full, max"
    }

    scan $jobs_text "%d" jobs
    if {$jobs < 1} {
        error "COMMON_VIVADO_JOBS must be greater than 0"
    }
    return $jobs
}

################################################################################
# 函数: common_configure_vivado_threads
# 作用: 将 COMMON_VIVADO_JOBS 应用到 Vivado 全局线程参数。
# 参数:
#   stage_dir 阶段目录/摘要记录目录。
# 返回:
#   - 未设置 COMMON_VIVADO_JOBS 时返回空字符串。
#   - 已设置时返回最终 jobs 数。
# 内部逻辑:
#   1. 调用 common_vivado_jobs 解析配置。
#   2. 未设置时不做任何操作，保持原有默认行为。
#   3. 设置时执行 set_param general.maxThreads <jobs>。
#   4. 记录 summary，便于之后从日志确认本次构建用了多少 jobs。
# 注意:
#   launch_runs 仍会显式传入 -jobs <jobs>；set_param 用于覆盖 Vivado 内部
#   支持该参数的多线程步骤。
################################################################################
proc common_configure_vivado_threads {stage_dir} {
    set jobs [common_vivado_jobs]
    if {$jobs eq ""} {
        return ""
    }

    if {[info exists ::common_vivado_threads_configured] && $::common_vivado_threads_configured eq $jobs} {
        return $jobs
    }

    puts "INFO: COMMON_VIVADO_JOBS=$jobs"
    if {[catch {set_param general.maxThreads $jobs} err]} {
        puts "WARN: set_param general.maxThreads $jobs failed: $err"
        common_append_summary $stage_dir "WARN: set_param general.maxThreads $jobs failed: $err"
    } else {
        common_append_summary $stage_dir "vivado_general_maxThreads: $jobs"
    }

    set ::common_vivado_threads_configured $jobs
    return $jobs
}

################################################################################
# 函数: common_launch_run
# 作用: 统一启动 Vivado run，并在需要时附加 -jobs 参数。
# 参数:
#   stage_dir 阶段目录/摘要记录目录。
#   run_name  run 名称，例如 synth_1 或 impl_1。
#   to_step   可选参数，默认空。非空时运行到指定步骤。
# 返回: 无显式返回值。
# 内部逻辑:
#   1. common_configure_vivado_threads 读取并应用 COMMON_VIVADO_JOBS。
#   2. jobs 为空时使用原始 launch_runs 命令，保持默认行为。
#   3. jobs 非空时使用 launch_runs <run> -jobs <jobs>。
#   4. to_step 非空时同时传入 -to_step <step>。
################################################################################
proc common_launch_run {stage_dir run_name {to_step ""}} {
    set jobs [common_configure_vivado_threads $stage_dir]
    if {$to_step eq ""} {
        if {$jobs eq ""} {
            puts "INFO: launch_runs $run_name"
            launch_runs $run_name
        } else {
            puts "INFO: launch_runs $run_name -jobs $jobs"
            launch_runs $run_name -jobs $jobs
        }
    } else {
        if {$jobs eq ""} {
            puts "INFO: launch_runs $run_name -to_step $to_step"
            launch_runs $run_name -to_step $to_step
        } else {
            puts "INFO: launch_runs $run_name -to_step $to_step -jobs $jobs"
            launch_runs $run_name -to_step $to_step -jobs $jobs
        }
    }
}


################################################################################
# 函数: common_summary_file
# 作用: 返回本次运行的统一摘要文件路径。
# 参数: 无。
# 返回: <run_root>/summary.txt。
# 注意: 本函数只拼路径，不创建文件；写入由 common_append_summary 完成。
################################################################################
proc common_summary_file {} {
    return [file join [common_run_root] "summary.txt"]
}

################################################################################
# 函数: common_tcl_status_file
# 作用: 返回 Tcl 构建状态文件路径。
# 参数: 无。
# 返回: <run_root>/status.txt。
# 注意: 本函数只拼路径，不创建文件；写入由 common_write_tcl_status 完成。
################################################################################
proc common_tcl_status_file {} {
    return [file join [common_run_root] "status.txt"]
}


################################################################################
# 函数: common_make_stage_dir
# 作用: 返回当前阶段的输出目录。
# 参数:
#   stage 阶段名称，例如 synth/impl/full_build。
# 返回: 当前实现中统一返回 reports 目录。
# 注意:
#   stage 参数保留给调用端表达阶段语义；当前函数未按 stage 再创建子目录。
################################################################################
proc common_make_stage_dir {stage} {
    return [common_reports_dir]
}


################################################################################
# 函数: common_append_summary
# 作用: 向统一摘要文件追加一行文本。
# 参数:
#   stage_dir 调用者所在阶段目录；当前仅保持接口一致，实际未用于拼路径。
#   line      要追加到 summary.txt 的一行内容。
# 返回: 无显式返回值。
# 内部逻辑:
#   1. open ... a 以追加模式打开文件，不存在则创建。
#   2. puts 写入一行。
#   3. close 关闭文件，确保内容落盘。
################################################################################
proc common_append_summary {stage_dir line} {
    set fp [open [common_summary_file] a]
    puts $fp $line
    close $fp
}

################################################################################
# 函数: common_template_project_xpr
# 作用: 返回模板/工作 Vivado 工程文件路径。
# 参数: 无。
# 返回: Prj.xpr 路径。
# 注意: 当前实现直接复用 common_project_xpr，保留该函数是为了兼容旧脚本接口。
################################################################################
proc common_template_project_xpr {} {
    return [common_project_xpr]
}

################################################################################
# 函数: common_project_work_dir
# 作用: 返回隔离 Vivado 工程副本目录。
# 参数: 无。
# 返回: <work_dir>/Prj_work。
# 用途: 构建过程在该目录创建/打开工程，避免污染源码目录。
################################################################################
proc common_project_work_dir {} {
    return [file join [common_work_dir] "Prj_work"]
}

################################################################################
# 函数: common_project_xpr
# 作用: 返回隔离 Vivado 工程的 .xpr 文件路径。
# 参数: 无。
# 返回: <work_dir>/Prj_work/Prj.xpr。
################################################################################
proc common_project_xpr {} {
    return [file join [common_project_work_dir] "Prj.xpr"]
}

################################################################################
# 函数: common_prepare_project_work_copy
# 作用: 确保隔离工作目录中存在 Vivado 工程文件 Prj.xpr。
# 参数: 无。
# 返回: 已存在或刚创建的 Prj.xpr 路径。
# 内部逻辑:
#   1. 如果 Prj.xpr 已存在，直接返回。
#   2. 创建 Prj_work 目录。
#   3. source 01_create_project.tcl，让该脚本从源码生成 Vivado 工程。
#   4. 再次检查 Prj.xpr 是否生成；没有生成则抛出 error。
################################################################################
proc common_prepare_project_work_copy {} {
    set work_project_dir [common_project_work_dir]
    set work_xpr [file join $work_project_dir "Prj.xpr"]

    if {[file exists $work_xpr]} {
        return $work_xpr
    }

    file mkdir $work_project_dir
    puts "INFO: Creating Vivado project from sources in isolated work directory."
    puts "INFO: Work project: $work_project_dir"
    source [file join [common_script_dir] "01_create_project.tcl"]

    if {![file exists $work_xpr]} {
        error "Project creation did not create expected .xpr: $work_xpr"
    }
    return $work_xpr
}

################################################################################
# 函数: common_open_or_rebuild_project
# 作用: 打开当前隔离工程；如果工程文件不存在则先创建。
# 参数: 无。
# 返回: 无显式返回值。
# 内部逻辑:
#   1. common_prepare_project_work_copy 确保 Prj.xpr 存在。
#   2. cd 到工程根目录，保证后续相对路径以根目录为基准。
#   3. 如果 Vivado 已经打开工程，则复用当前工程。
#   4. 否则 open_project 打开隔离工程。
#   5. 打开失败时抛出 error。
#   6. 导出基础工程报告，例如 manifest/compile_order/ip_status。
################################################################################
proc common_open_or_rebuild_project {} {
    set root_dir [common_root_dir]
    set xpr_path [common_prepare_project_work_copy]
    cd $root_dir

    set open_project_name [current_project -quiet]
    if {$open_project_name ne ""} {
        puts "INFO: Project already open: $open_project_name"
        return
    }

    if {[current_project -quiet] eq ""} {
        puts "INFO: Opening isolated project: $xpr_path"
        open_project $xpr_path
    }

    if {[current_project -quiet] eq ""} {
        error "No Vivado project is open after open/rebuild step."
    }

    common_export_project_reports [common_reports_dir]
}

################################################################################
# 函数: common_run_status
# 作用: 查询 Vivado run 的状态字符串。
# 参数:
#   run_name run 名称，例如 synth_1 或 impl_1。
# 返回:
#   - run 不存在时返回 MISSING。
#   - run 存在时返回 Vivado STATUS 属性，例如 "synth_design Complete!"。
################################################################################
proc common_run_status {run_name} {
    set run_obj [get_runs -quiet $run_name]
    if {$run_obj eq ""} {
        return "MISSING"
    }
    return [get_property STATUS $run_obj]
}

################################################################################
# 函数: common_run_complete
# 作用: 判断指定 run 是否已经完成。
# 参数:
#   run_name run 名称，例如 synth_1 或 impl_1。
# 返回: 完成返回 1，否则返回 0。
# 内部逻辑:
#   1. 读取 STATUS 属性。
#   2. 使用 string match -nocase 做大小写不敏感匹配。
#   3. 同时兼容一般 complete 和 write_bitstream complete 两类状态文本。
################################################################################
proc common_run_complete {run_name} {
    set status [common_run_status $run_name]
    if {[string match -nocase "*complete*" $status] || [string match -nocase "*write_bitstream complete*" $status]} {
        return 1
    }
    return 0
}

################################################################################
# 函数: common_require_run
# 作用: 确认指定 Vivado run 存在。
# 参数:
#   run_name run 名称。
# 返回: run 存在时无显式返回值；run 缺失时抛出 error。
# 用途: 在 launch/reset run 前提前给出清晰错误。
################################################################################
proc common_require_run {run_name} {
    if {[get_runs -quiet $run_name] eq ""} {
        error "Missing Vivado run: $run_name"
    }
}

################################################################################
# 函数: common_update_compile_order
# 作用: 更新 Vivado sources_1 和 sim_1 fileset 的编译顺序。
# 参数: 无。
# 返回: 无显式返回值。
# 内部逻辑:
#   1. get_filesets -quiet 检查 fileset 是否存在，避免不存在时报错。
#   2. 对存在的 sources_1/sim_1 执行 update_compile_order。
################################################################################
proc common_update_compile_order {} {
    if {[get_filesets -quiet sources_1] ne ""} {
        update_compile_order -fileset sources_1
    }
    if {[get_filesets -quiet sim_1] ne ""} {
        update_compile_order -fileset sim_1
    }
}


################################################################################
# 函数: common_safe_report
# 作用: 安全执行一个 Vivado report 命令，并把结果写入 reports 目录。
# 参数:
#   stage_dir    阶段目录；用于记录摘要，报告实际统一写入 common_reports_dir。
#   report_name  输出报告文件名，例如 synth_utilization.rpt。
#   command_text Vivado 报告命令文本，例如 report_utilization。
# 返回: 无显式返回值。
# 内部逻辑:
#   1. 拼出报告路径。
#   2. uplevel 1 在调用者上一层作用域执行报告命令。
#   3. 自动给命令追加 -file {report_path}。
#   4. catch 捕获报告失败，失败只记录 WARN，不中断整个构建。
# Tcl 说明:
#   uplevel 1 "$command_text -file {$report_path}" 中的 1 表示在调用者作用域执行；
#   这样可以让 Vivado 命令看到调用上下文中的对象/设置。
################################################################################
proc common_safe_report {stage_dir report_name command_text} {
    set report_path [file join [common_reports_dir] $report_name]
    puts "INFO: Writing report: $report_path"
    if {[catch {uplevel 1 "$command_text -file {$report_path}"} err]} {
        puts "WARN: Report failed: $report_name"
        puts "WARN: $err"
        common_append_summary $stage_dir "WARN: report failed: $report_name - $err"
    } else {
        common_append_summary $stage_dir "report: $report_path"
    }
}

################################################################################
# 函数: common_open_run_if_possible
# 作用: 尝试打开指定 run，用于后续导出该 run 的报告。
# 参数:
#   stage_dir 摘要记录目录/阶段目录。
#   run_name  run 名称，例如 synth_1 或 impl_1。
# 返回: 打开成功返回 1，失败返回 0。
# 内部逻辑:
#   使用 catch 包住 open_run；失败时记录 WARN，不直接终止构建。
################################################################################
proc common_open_run_if_possible {stage_dir run_name} {
    if {[catch {open_run $run_name} err]} {
        puts "WARN: open_run $run_name failed: $err"
        common_append_summary $stage_dir "WARN: open_run $run_name failed: $err"
        return 0
    }
    return 1
}

################################################################################
# 函数: common_export_synth_reports
# 作用: 导出综合阶段常用报告。
# 参数:
#   stage_dir 阶段目录/摘要记录目录。
# 返回: 无显式返回值。
# 内部逻辑:
#   1. 先 open_run synth_1，失败则跳过。
#   2. 导出资源利用率、时序摘要和 DRC 报告。
################################################################################
proc common_export_synth_reports {stage_dir} {
    if {![common_open_run_if_possible $stage_dir "synth_1"]} {
        return
    }
    common_safe_report $stage_dir "synth_utilization.rpt" "report_utilization"
    common_safe_report $stage_dir "synth_timing_summary.rpt" "report_timing_summary"
    common_safe_report $stage_dir "synth_drc.rpt" "report_drc"
}

################################################################################
# 函数: common_export_impl_reports
# 作用: 导出实现阶段常用报告。
# 参数:
#   stage_dir 阶段目录/摘要记录目录。
# 返回: 无显式返回值。
# 内部逻辑:
#   1. 先 open_run impl_1，失败则跳过。
#   2. 导出资源、时序、DRC、IO 和时钟交互报告。
################################################################################
proc common_export_impl_reports {stage_dir} {
    if {![common_open_run_if_possible $stage_dir "impl_1"]} {
        return
    }
    common_safe_report $stage_dir "impl_utilization.rpt" "report_utilization"
    common_safe_report $stage_dir "impl_timing_summary.rpt" "report_timing_summary"
    common_safe_report $stage_dir "impl_drc.rpt" "report_drc"
    common_safe_report $stage_dir "impl_io.rpt" "report_io"
    common_safe_report $stage_dir "impl_clock_interaction.rpt" "report_clock_interaction"
}

################################################################################
# 函数: common_write_manifest
# 作用: 写出本次构建的 manifest.txt，记录工程和运行环境关键信息。
# 参数: 无。
# 返回: manifest.txt 文件路径。
# 内部逻辑:
#   1. 在 reports 目录创建/覆盖 manifest.txt。
#   2. 写入生成时间、工程名、根目录、运行目录、工作目录和 .xpr 路径。
#   3. 如果当前 Vivado 工程已打开，继续写入工程名、工程目录、器件型号、
#      顶层模块、源文件数量和 IP 数量。
#   4. 将 manifest 路径追加到 summary.txt。
################################################################################
proc common_write_manifest {} {
    set manifest_path [file join [common_reports_dir] "manifest.txt"]
    set fp [open $manifest_path w]
    puts $fp "generated_at=[clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]"
    puts $fp "project_name=[common_project_name]"
    puts $fp "root_dir=[common_root_dir]"
    puts $fp "run_dir=[common_run_root]"
    puts $fp "work_dir=[common_work_dir]"
    puts $fp "project_xpr=[common_project_xpr]"
    set vivado_jobs [common_vivado_jobs]
    if {$vivado_jobs ne ""} {
        puts $fp "vivado_jobs=$vivado_jobs"
    }
    if {[current_project -quiet] ne ""} {
        puts $fp "vivado_project=[current_project]"
        puts $fp "vivado_project_dir=[get_property DIRECTORY [current_project]]"
        puts $fp "vivado_part=[get_property PART [current_project]]"
        if {[get_filesets -quiet sources_1] ne ""} {
            puts $fp "top_module=[get_property top [current_fileset]]"
            puts $fp "source_file_count=[llength [get_files -quiet -of_objects [get_filesets sources_1]]]"
        }
        puts $fp "ip_count=[llength [get_ips -quiet]]"
    }
    close $fp
    common_append_summary [common_reports_dir] "manifest: $manifest_path"
    return $manifest_path
}

################################################################################
# 函数: common_export_project_reports
# 作用: 导出与工程本身相关的基础报告。
# 参数:
#   stage_dir 阶段目录/摘要记录目录。
# 返回: 无显式返回值。
# 内部逻辑:
#   1. 始终先写 manifest。
#   2. 如果当前没有打开 Vivado 工程，则记录 WARN 后返回。
#   3. sources_1 存在时导出 compile_order.rpt。
#   4. 工程中存在 IP 时导出 ip_status.rpt。
################################################################################
proc common_export_project_reports {stage_dir} {
    common_write_manifest
    if {[current_project -quiet] eq ""} {
        common_append_summary $stage_dir "WARN: project reports skipped because no project is open"
        return
    }
    if {[get_filesets -quiet sources_1] ne ""} {
        common_safe_report $stage_dir "compile_order.rpt" "report_compile_order -fileset sources_1"
    }
    if {[llength [get_ips -quiet]] > 0} {
        common_safe_report $stage_dir "ip_status.rpt" "report_ip_status"
    }
}

################################################################################
# 函数: common_run_synth
# 作用: 运行 Vivado 综合 run synth_1。
# 参数:
#   stage_dir   阶段目录/摘要记录目录。
#   reset_first 可选参数，默认 1。为 1 时运行前 reset_run synth_1。
# 返回: 综合成功完成时无显式返回值；失败时抛出 error。
# 内部逻辑:
#   1. 检查 synth_1 是否存在。
#   2. 更新编译顺序。
#   3. 根据 reset_first 决定是否清理旧综合结果。
#   4. common_launch_run 启动综合，并按 COMMON_VIVADO_JOBS 追加 -jobs。
#   5. 记录状态、复制 run 日志、写 status.txt。
#   6. 如果状态不包含 complete，则抛出 error。
################################################################################
proc common_run_synth {stage_dir {reset_first 1}} {
    common_require_run synth_1
    common_update_compile_order
    if {$reset_first} {
        puts "INFO: reset_run synth_1"
        reset_run synth_1
    }
    common_launch_run $stage_dir synth_1
    wait_on_run synth_1
    set status [common_run_status synth_1]
    common_append_summary $stage_dir "synth_1 status: $status"
    common_copy_run_logs
    common_write_tcl_status
    if {![common_run_complete synth_1]} {
        error "synth_1 did not complete successfully. Status: $status"
    }
}

################################################################################
# 函数: common_ensure_synth_complete
# 作用: 确保 synth_1 已完成，供实现阶段依赖。
# 参数:
#   stage_dir 阶段目录/摘要记录目录。
# 返回: synth_1 完成时无显式返回值；无法完成时由 common_run_synth 抛错。
# 内部逻辑:
#   1. 检查 synth_1 是否存在。
#   2. 如果已经完成，只记录状态并返回。
#   3. 如果未完成，则自动调用 common_run_synth，且 reset_first 为 0，
#      让 Vivado 在现有状态基础上继续/运行综合。
################################################################################
proc common_ensure_synth_complete {stage_dir} {
    common_require_run synth_1
    if {[common_run_complete synth_1]} {
        common_append_summary $stage_dir "synth_1 already complete: [common_run_status synth_1]"
        return
    }
    common_append_summary $stage_dir "synth_1 was not complete; running synth_1 automatically."
    common_run_synth $stage_dir 0
}

################################################################################
# 函数: common_run_impl
# 作用: 运行 Vivado 实现 run impl_1，可选择运行到指定步骤。
# 参数:
#   stage_dir   阶段目录/摘要记录目录。
#   reset_first 可选参数，默认 1。为 1 时运行前 reset_run impl_1。
#   to_step     可选参数，默认空。非空时实现运行到指定步骤。
# 返回: 实现成功完成时无显式返回值；失败时抛出 error。
# 内部逻辑:
#   1. 检查 impl_1 是否存在。
#   2. 确保 synth_1 已完成，因为实现依赖综合结果。
#   3. 根据 reset_first 决定是否清理旧实现结果。
#   4. common_launch_run 根据 to_step 决定完整运行 impl_1，或运行到指定步骤
#      例如 write_bitstream，并按 COMMON_VIVADO_JOBS 追加 -jobs。
#   5. 等待 run 结束，记录状态、复制日志、写 status.txt。
#   6. 如果状态不包含 complete，则抛出 error。
################################################################################
proc common_run_impl {stage_dir {reset_first 1} {to_step ""}} {
    common_require_run impl_1
    common_ensure_synth_complete $stage_dir
    if {$reset_first} {
        puts "INFO: reset_run impl_1"
        reset_run impl_1
    }
    common_launch_run $stage_dir impl_1 $to_step
    wait_on_run impl_1
    set status [common_run_status impl_1]
    common_append_summary $stage_dir "impl_1 status: $status"
    common_copy_run_logs
    common_write_tcl_status
    if {![common_run_complete impl_1]} {
        error "impl_1 did not complete successfully. Status: $status"
    }
}


################################################################################
# 函数: common_debug_insertions
# 作用: 根据 ENABLE_DEBUG 环境变量，为 impl_1 配置或清理 opt_design 前置 hook。
# 参数:
#   stage_dir 阶段目录/摘要记录目录。
#   verbose   可选参数，默认 1。当前保留接口，函数内部未使用该参数。
# 返回: 无显式返回值；配置冲突或文件缺失时抛出 error。
# 背景:
#   Vivado run 属性 STEPS.OPT_DESIGN.TCL.PRE 可以指定一个 Tcl 脚本，
#   在 opt_design 步骤前执行。这里用它自动 source tcl/debug/*.tcl，
#   便于在实现前插入 ILA/debug 逻辑。
# 内部逻辑:
#   1. 检查 impl_1 是否存在。
#   2. 计算 debug 脚本目录、聚合 hook 文件路径和旧版 hook 路径。
#   3. 读取 ENABLE_DEBUG，只有值为 "1" 才启用 debug 插入系统。
#   4. 如果未启用，则只清理本脚本生成过的 hook，避免影响用户自定义 hook。
#   5. 如果启用，则扫描 tcl/debug/*.tcl，生成聚合 hook 文件。
#   6. 设置 impl_1 的 STEPS.OPT_DESIGN.TCL.PRE 指向聚合 hook。
################################################################################
proc common_debug_insertions {stage_dir {verbose 1}} {
    set impl_run_name "impl_1"
    common_require_run $impl_run_name

    # 聚合 hook 放在本次 stage_dir 下；真正的 debug Tcl 源文件放在 tcl/debug。
    set debug_dir [file normalize [file join [common_root_dir] "tcl" "debug"]]
    set aggregate_hook [file normalize [file join $stage_dir "opt_design_pre_debug_insertions.tcl"]]
    set legacy_lclk_hook [file normalize [file join $debug_dir "insert_ila_spy_lclk.tcl"]]
    set legacy_lclk_hook_typo [file normalize [file join $debug_dir "inser_ila_spy_lclk.tcl"]]

    # Tcl 中环境变量都在 ::env 数组里；这里仅把 ENABLE_DEBUG=1 视为启用。
    set enable_debug 0
    if {[info exists ::env(ENABLE_DEBUG)] && $::env(ENABLE_DEBUG) eq "1"} {
        set enable_debug 1
    }

    # Vivado run 属性保存 hook 路径；规范化路径便于和已知生成文件比较。
    set run_obj [get_runs $impl_run_name]
    set hook_prop "STEPS.OPT_DESIGN.TCL.PRE"
    set current_hook [get_property $hook_prop $run_obj]
    set current_hook_norm ""
    if {$current_hook ne ""} {
        set current_hook_norm [file normalize $current_hook]
    }

    if {!$enable_debug} {
        puts "INFO: ENABLE_DEBUG is not 1, debug insertion system disabled"
        common_append_summary $stage_dir "debug_insertions: ENABLE_DEBUG disabled"
        # 未设置 hook 时无需处理。
        if {$current_hook eq ""} {
            return
        }
        # 只清理本工具生成的聚合 hook 或旧版 l_clk hook；其它用户 hook 保留。
        if {[file tail $current_hook_norm] eq "opt_design_pre_debug_insertions.tcl"} {
            puts "INFO: Clearing stale debug insertion aggregate hook from $impl_run_name"
            set_property $hook_prop {} $run_obj
            common_append_summary $stage_dir "debug_insertions: cleared stale aggregate hook"
        } elseif {$current_hook_norm eq $legacy_lclk_hook || $current_hook_norm eq $legacy_lclk_hook_typo} {
            puts "INFO: Clearing stale legacy l_clk debug hook from $impl_run_name"
            set_property $hook_prop {} $run_obj
            common_append_summary $stage_dir "debug_insertions: cleared stale legacy l_clk hook"
        } else {
            puts "WARN: Existing $impl_run_name $hook_prop is not a generated debug hook; leaving unchanged: $current_hook"
            common_append_summary $stage_dir "WARN: debug_insertions left existing impl hook unchanged: $current_hook"
        }
        return
    }

    puts "INFO: ENABLE_DEBUG=1, debug insertion system enabled"

    if {![file isdirectory $debug_dir]} {
        error "Missing debug Tcl directory: $debug_dir"
    }

    set debug_tcl_files [lsort [glob -nocomplain [file join $debug_dir "*.tcl"]]]
    if {[llength $debug_tcl_files] == 0} {
        error "ENABLE_DEBUG=1 but no debug Tcl files found under $debug_dir"
    }

    # 如果 impl_1 已经有非本工具生成的 hook，停止执行，避免覆盖用户自定义流程。
    if {$current_hook ne "" \
        && $current_hook_norm ne $aggregate_hook \
        && [file tail $current_hook_norm] ne "opt_design_pre_debug_insertions.tcl" \
        && $current_hook_norm ne $legacy_lclk_hook \
        && $current_hook_norm ne $legacy_lclk_hook_typo} {
        puts "WARN: Existing $impl_run_name $hook_prop is not empty: $current_hook"
        puts "WARN: Refusing to overwrite existing implementation hook with generated debug aggregate hook."
        error "Existing implementation pre-opt hook would be overwritten"
    }

    # 生成聚合 hook: Vivado 执行该 hook 时，会按文件名排序依次 source tcl/debug/*.tcl。
    set fp [open $aggregate_hook w]
    puts $fp "# Auto-generated by common_debug_insertions."
    puts $fp "# This file is regenerated when ENABLE_DEBUG=1."
    puts $fp "puts \"INFO: opt_design_pre_debug_insertions.tcl: sourcing debug Tcl files\""
    puts $fp "set common_debug_tcl_files \[list \\"
    foreach debug_tcl $debug_tcl_files {
        puts $fp "    {$debug_tcl} \\"
    }
    puts $fp "\]"
    puts $fp "foreach common_debug_tcl \$common_debug_tcl_files {"
    puts $fp "    puts \"INFO: opt_design_pre_debug_insertions.tcl: source \$common_debug_tcl\""
    puts $fp "    source \$common_debug_tcl"
    puts $fp "}"
    puts $fp "puts \"INFO: opt_design_pre_debug_insertions.tcl: done\""
    close $fp

    # 写控制台和 summary，方便批处理日志中确认究竟调度了哪些 debug 脚本。
    puts "INFO: Generated debug aggregate hook: $aggregate_hook"
    foreach debug_tcl $debug_tcl_files {
        puts "INFO: Debug Tcl scheduled: $debug_tcl"
        common_append_summary $stage_dir "debug_insertions: scheduled $debug_tcl"
    }

    puts "INFO: Setting $impl_run_name $hook_prop to $aggregate_hook"
    set_property $hook_prop $aggregate_hook $run_obj
    common_append_summary $stage_dir "debug_insertions: aggregate hook enabled: $aggregate_hook"
}

################################################################################
# 函数: common_find_bit_files
# 作用: 查找实现目录下生成的 bitstream 文件。
# 参数: 无。
# 返回: .bit 文件路径列表；未找到时返回空列表。
# 内部逻辑:
#   glob -nocomplain 在匹配不到文件时返回空列表，而不是报错。
################################################################################
proc common_find_bit_files {} {
    return [glob -nocomplain [file join [common_project_work_dir] "Prj.runs" "impl_1" "*.bit"]]
}

################################################################################
# 函数: common_find_artifact_files
# 作用: 查找需要归档的主要构建产物。
# 参数: 无。
# 返回: 文件路径列表，可能包含 .bit/.ltx/.dcp/.xsa/.hwh。
# 内部逻辑:
#   1. 定义多个 glob 匹配模式。
#   2. 遍历每个模式，把匹配到的文件 lappend 到 files 列表。
#   3. 返回汇总列表。
################################################################################
proc common_find_artifact_files {} {
    set patterns [list \
        [file join [common_project_work_dir] "Prj.runs" "impl_1" "*.bit"] \
        [file join [common_project_work_dir] "Prj.runs" "impl_1" "*.ltx"] \
        [file join [common_project_work_dir] "Prj.runs" "impl_1" "*.dcp"] \
        [file join [common_project_work_dir] "Prj.hw" "*.xsa"] \
        [file join [common_project_work_dir] "Prj.sdk" "*.hwh"] \
    ]
    set files {}
    foreach pattern $patterns {
        foreach file_path [glob -nocomplain $pattern] {
            lappend files $file_path
        }
    }
    return $files
}

################################################################################
# 函数: common_copy_artifacts
# 作用: 把主要构建产物复制到统一 artifacts 目录。
# 参数: 无。
# 返回: 成功复制的文件数量。
# 内部逻辑:
#   1. common_find_artifact_files 找到候选文件。
#   2. file isfile 确认候选项是普通文件。
#   3. file copy -force 覆盖复制到 artifacts 目录。
#   4. 每复制一个文件就记录到 summary.txt，并递增计数。
################################################################################
proc common_copy_artifacts {} {
    set count 0
    foreach file_path [common_find_artifact_files] {
        if {[file isfile $file_path]} {
            set dst [file join [common_artifacts_dir] [file tail $file_path]]
            file copy -force $file_path $dst
            common_append_summary [common_artifacts_dir] "artifact: $dst"
            incr count
        }
    }
    return $count
}

################################################################################
# 函数: common_copy_run_logs
# 作用: 复制 synth_1 和 impl_1 的 runme.log 到统一 logs 目录。
# 参数: 无。
# 返回: 成功复制的日志文件数量。
# 内部逻辑:
#   1. 固定遍历 synth_1 和 impl_1。
#   2. 检查 <Prj_work>/Prj.runs/<run>/runme.log 是否存在。
#   3. 存在则复制为 <logs>/<run>_runme.log。
#   4. 记录 summary 并递增计数。
################################################################################
proc common_copy_run_logs {} {
    set copied 0
    foreach run_name {synth_1 impl_1} {
        set src [file join [common_project_work_dir] "Prj.runs" $run_name "runme.log"]
        if {[file exists $src]} {
            set dst [file join [common_logs_dir] "${run_name}_runme.log"]
            file copy -force $src $dst
            common_append_summary [common_logs_dir] "log: $dst"
            incr copied
        }
    }
    return $copied
}

################################################################################
# 函数: common_write_tcl_status
# 作用: 追加写入 Tcl 构建状态，供外部脚本读取。
# 参数:
#   bitstream_found 可选参数，默认空字符串。
#                   为空时函数自动检查是否存在 .bit 文件；
#                   非空时按调用者传入值写入。
# 返回: 无显式返回值。
# 内部逻辑:
#   1. 查询 synth_1 和 impl_1 的状态。
#   2. 如果未传入 bitstream_found，则通过 common_find_bit_files 自动判断。
#   3. 以追加模式打开 status.txt。
#   4. 写入 tcl_synth_status/tcl_impl_status/tcl_bitstream_found 三个键值。
################################################################################
proc common_write_tcl_status {{bitstream_found ""}} {
    set synth_status [common_run_status synth_1]
    set impl_status [common_run_status impl_1]
    if {$bitstream_found eq ""} {
        set bitstream_found [expr {[llength [common_find_bit_files]] > 0 ? 1 : 0}]
    }
    set fp [open [common_tcl_status_file] a]
    puts $fp "tcl_synth_status=$synth_status"
    puts $fp "tcl_impl_status=$impl_status"
    puts $fp "tcl_bitstream_found=$bitstream_found"
    close $fp
}
