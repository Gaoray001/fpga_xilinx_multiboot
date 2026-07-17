#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT" || exit 1

source /tools/Xilinx/Vivado/2018.3/settings64.sh

find _runs/latest/work/Prj_work -maxdepth 2 -name "*.xpr" -print

vivado _runs/latest/work/Prj_work/*.xpr &