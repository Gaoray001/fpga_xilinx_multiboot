#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
VIVADO_SETTINGS="${VIVADO_SETTINGS:-/tools/Xilinx/Vivado/2018.3/settings64.sh}"
LATEST_XPR="$ROOT_DIR/_runs/latest/work/Prj_work/Prj.xpr"

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/vivadogui.sh

Opens the generated Vivado project from _runs/latest/work/Prj_work/.

Environment:
  VIVADO_SETTINGS=/tools/Xilinx/Vivado/2018.3/settings64.sh
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -gt 0 ]]; then
  echo "ERROR: unexpected argument: $1" >&2
  usage
  exit 1
fi

if [[ ! -f "$VIVADO_SETTINGS" ]]; then
  echo "ERROR: Vivado settings file not found: $VIVADO_SETTINGS" >&2
  exit 1
fi

if [[ ! -f "$LATEST_XPR" ]]; then
  echo "ERROR: latest Vivado project not found: $LATEST_XPR" >&2
  echo "Run ./scripts/vivado2018_common.sh create or a build command first." >&2
  exit 1
fi

source "$VIVADO_SETTINGS"

if ! command -v vivado >/dev/null 2>&1; then
  echo "ERROR: vivado command not found after sourcing $VIVADO_SETTINGS" >&2
  exit 1
fi

exec vivado -mode tcl -source <(printf 'open_project {%s}\n' "$LATEST_XPR")
