# Minimal project-local XSim smoke test entry.
#
# Intended call path:
#   ./scripts/vivado2018_common.sh xsim-smoke
#     -> vivado -mode batch -source tcl/sim/xsim_smoke.tcl
#     -> xvlog / xelab / xsim
#     -> sim/tb/tb_xsim_smoke.v prints RESULT=PASS or RESULT=FAIL

proc env_or_default {name fallback} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $fallback
}

proc run_external_cmd {cmd_list} {
    puts "INFO: [join $cmd_list { }]"
    if {[catch {exec {*}$cmd_list} output]} {
        if {$output ne ""} {
            puts $output
        }
        error "external command failed: [join $cmd_list { }]"
    }
    if {$output ne ""} {
        puts $output
    }
}

set SCRIPT_DIR [file dirname [file normalize [info script]]]
set ROOT_DIR   [file dirname [file dirname $SCRIPT_DIR]]
if {[info exists ::env(COMMON_VIVADO_ROOT_DIR)] && $::env(COMMON_VIVADO_ROOT_DIR) ne ""} {
    set ROOT_DIR $::env(COMMON_VIVADO_ROOT_DIR)
}

set WORK_DIR      [env_or_default "COMMON_VIVADO_WORK_DIR"      [file join $ROOT_DIR "sim" "xsim" "work"]]
set LOGS_DIR      [env_or_default "COMMON_VIVADO_LOGS_DIR"      [file join $ROOT_DIR "sim" "xsim" "logs"]]
set ARTIFACTS_DIR [env_or_default "COMMON_VIVADO_ARTIFACTS_DIR" [file join $ROOT_DIR "sim" "wave"]]

set SIM_WORK_DIR [file join $WORK_DIR "xsim_smoke"]
file mkdir $SIM_WORK_DIR
file mkdir $LOGS_DIR
file mkdir $ARTIFACTS_DIR

set DUT_FILE [file join $ROOT_DIR "rtl" "hdl" "user" "xsim_smoke_dut.v"]
set TB_FILE  [file join $ROOT_DIR "sim" "tb" "tb_xsim_smoke.v"]

set SNAPSHOT_NAME "xsim_smoke_snapshot"
set XVLOG_LOG     [file join $LOGS_DIR "xsim_smoke_xvlog.log"]
set XELAB_LOG     [file join $LOGS_DIR "xsim_smoke_xelab.log"]
set XSIM_LOG      [file join $LOGS_DIR "xsim_smoke_xsim.log"]
set XSIM_BATCH    [file join $SIM_WORK_DIR "xsim_smoke_run.tcl"]
set WDB_FILE      [file join $ARTIFACTS_DIR "xsim_smoke.wdb"]

foreach src_file [list $DUT_FILE $TB_FILE] {
    if {![file exists $src_file]} {
        error "required simulation source is missing: $src_file"
    }
}

set batch_fh [open $XSIM_BATCH w]
puts $batch_fh "log_wave -recursive *"
puts $batch_fh "run all"
puts $batch_fh "quit"
close $batch_fh

puts "INFO: xsim_smoke ROOT_DIR      = $ROOT_DIR"
puts "INFO: xsim_smoke SIM_WORK_DIR  = $SIM_WORK_DIR"
puts "INFO: xsim_smoke LOGS_DIR      = $LOGS_DIR"
puts "INFO: xsim_smoke ARTIFACTS_DIR = $ARTIFACTS_DIR"
puts "INFO: xsim_smoke WDB_FILE      = $WDB_FILE"

cd $SIM_WORK_DIR

set compile_files [list $DUT_FILE $TB_FILE]
set xvlog_cmd [concat [list xvlog -work xil_defaultlib -log $XVLOG_LOG] $compile_files]
run_external_cmd $xvlog_cmd

set xelab_cmd [list xelab -debug typical -L xil_defaultlib -snapshot $SNAPSHOT_NAME xil_defaultlib.tb_xsim_smoke -log $XELAB_LOG]
run_external_cmd $xelab_cmd

set xsim_cmd [list xsim $SNAPSHOT_NAME -tclbatch $XSIM_BATCH -wdb $WDB_FILE -log $XSIM_LOG]
run_external_cmd $xsim_cmd

if {![file exists $XSIM_LOG]} {
    error "xsim log was not generated: $XSIM_LOG"
}

set log_fh [open $XSIM_LOG r]
set sim_log [read $log_fh]
close $log_fh

if {[string first "RESULT=FAIL" $sim_log] >= 0} {
    error "XSim smoke test reported RESULT=FAIL; see $XSIM_LOG"
}

if {[string first "RESULT=PASS" $sim_log] < 0} {
    error "XSim smoke test did not report RESULT=PASS; see $XSIM_LOG"
}

puts "INFO: XSim smoke test reported RESULT=PASS"
puts "INFO: XSim smoke log: $XSIM_LOG"
puts "INFO: XSim smoke WDB: $WDB_FILE"
