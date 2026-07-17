set SCRIPT_DIR [file dirname [file normalize [info script]]]
source [file join $SCRIPT_DIR "common_utils.tcl"]

set STAGE_DIR [common_make_stage_dir "synth"]
common_append_summary $STAGE_DIR "command: synth"
common_append_summary $STAGE_DIR "root: [common_root_dir]"

common_open_or_rebuild_project
common_run_synth $STAGE_DIR 1
common_export_synth_reports $STAGE_DIR
common_copy_run_logs
common_write_tcl_status

common_append_summary $STAGE_DIR "done: synth"
puts "INFO: Synthesis finished."
puts "INFO: Summary: [common_summary_file]"
