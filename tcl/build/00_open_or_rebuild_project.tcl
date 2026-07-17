set SCRIPT_DIR [file dirname [file normalize [info script]]]
source [file join $SCRIPT_DIR "common_utils.tcl"]

set STAGE_DIR [common_make_stage_dir "open"]
common_append_summary $STAGE_DIR "command: open_or_rebuild_project"
common_append_summary $STAGE_DIR "root: [common_root_dir]"
common_append_summary $STAGE_DIR "xpr: [common_project_xpr]"

common_open_or_rebuild_project

common_append_summary $STAGE_DIR "project: [current_project]"
common_append_summary $STAGE_DIR "project_dir: [get_property DIRECTORY [current_project]]"
common_append_summary $STAGE_DIR "part: [get_property PART [current_project]]"
common_append_summary $STAGE_DIR "synth_1 status: [common_run_status synth_1]"
common_append_summary $STAGE_DIR "impl_1 status: [common_run_status impl_1]"
common_write_tcl_status

puts "INFO: Open/rebuild finished."
puts "INFO: Summary: [common_summary_file]"
