set SCRIPT_DIR [file dirname [file normalize [info script]]]
source [file join $SCRIPT_DIR "common_utils.tcl"]

set STAGE_DIR [common_make_stage_dir "impl"]
common_append_summary $STAGE_DIR "command: impl"
common_append_summary $STAGE_DIR "root: [common_root_dir]"

common_open_or_rebuild_project
common_run_impl $STAGE_DIR 1 ""
common_export_impl_reports $STAGE_DIR
common_copy_run_logs
common_write_tcl_status

common_append_summary $STAGE_DIR "done: impl"
puts "INFO: Implementation finished."
puts "INFO: Summary: [common_summary_file]"
