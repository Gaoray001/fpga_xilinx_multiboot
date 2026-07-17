set SCRIPT_DIR [file dirname [file normalize [info script]]]
source [file join $SCRIPT_DIR "common_utils.tcl"]

set STAGE_DIR [common_make_stage_dir "clean_runs"]
common_append_summary $STAGE_DIR "command: clean-runs"
common_append_summary $STAGE_DIR "root: [common_root_dir]"
common_append_summary $STAGE_DIR "risk: reset_run clears Vivado run state for synth_1/impl_1 only."
common_append_summary $STAGE_DIR "risk: source RTL, XDC, Doc, Tcl, board_ai_workflow, _artifacts, and _backups are not deleted."

common_open_or_rebuild_project

foreach run_name {impl_1 synth_1} {
    if {[get_runs -quiet $run_name] ne ""} {
        puts "INFO: reset_run $run_name"
        reset_run $run_name
        common_append_summary $STAGE_DIR "$run_name reset"
    } else {
        common_append_summary $STAGE_DIR "$run_name missing, skip"
    }
}

common_write_tcl_status
common_append_summary $STAGE_DIR "done: clean-runs"
puts "INFO: Run reset finished."
puts "INFO: Summary: [common_summary_file]"
