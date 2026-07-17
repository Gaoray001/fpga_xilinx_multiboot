set SCRIPT_DIR [file dirname [file normalize [info script]]]
source [file join $SCRIPT_DIR "common_utils.tcl"]

set STAGE_DIR [common_make_stage_dir "reports"]
common_append_summary $STAGE_DIR "command: reports"
common_append_summary $STAGE_DIR "root: [common_root_dir]"

common_open_or_rebuild_project

if {[common_run_complete synth_1]} {
    common_append_summary $STAGE_DIR "exporting synth_1 reports"
    common_export_synth_reports $STAGE_DIR
} else {
    common_append_summary $STAGE_DIR "skip synth_1 reports, status: [common_run_status synth_1]"
}

if {[common_run_complete impl_1]} {
    common_append_summary $STAGE_DIR "exporting impl_1 reports"
    common_export_impl_reports $STAGE_DIR
} else {
    common_append_summary $STAGE_DIR "skip impl_1 reports, status: [common_run_status impl_1]"
}

common_append_summary $STAGE_DIR "done: reports"
common_copy_run_logs
common_write_tcl_status
puts "INFO: Report export finished."
puts "INFO: Summary: [common_summary_file]"
