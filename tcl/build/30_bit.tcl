set SCRIPT_DIR [file dirname [file normalize [info script]]]
source [file join $SCRIPT_DIR "common_utils.tcl"]

set STAGE_DIR [common_make_stage_dir "bit"]
common_append_summary $STAGE_DIR "command: bit"
common_append_summary $STAGE_DIR "root: [common_root_dir]"

common_open_or_rebuild_project
common_run_impl $STAGE_DIR 0 "write_bitstream"
common_export_impl_reports $STAGE_DIR
common_copy_run_logs

set bit_files [common_find_bit_files]
if {[llength $bit_files] == 0} {
    common_write_tcl_status 0
    common_append_summary $STAGE_DIR "ERROR: no bitstream found under work/Prj_work/Prj.runs/impl_1"
    error "No bitstream found under work/Prj_work/Prj.runs/impl_1"
}

foreach bit_file $bit_files {
    common_append_summary $STAGE_DIR "bitstream: $bit_file"
}
set artifact_count [common_copy_artifacts]
common_append_summary $STAGE_DIR "artifacts_copied: $artifact_count"
common_write_tcl_status 1

common_append_summary $STAGE_DIR "done: bit"
puts "INFO: Bitstream generation finished."
puts "INFO: Summary: [common_summary_file]"
