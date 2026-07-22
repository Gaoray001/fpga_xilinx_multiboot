#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VIVADO_SETTINGS="${VIVADO_SETTINGS:-/tools/Xilinx/Vivado/2018.3/settings64.sh}"
LATEST_ARTIFACTS="${PROJECT_ROOT}/_artifacts/latest"

if [[ ! -f "$VIVADO_SETTINGS" ]]; then
  echo "ERROR: Vivado settings file not found: $VIVADO_SETTINGS" >&2
  exit 1
fi

if [[ ! -e "$LATEST_ARTIFACTS" ]]; then
  echo "ERROR: latest artifacts path does not exist: $LATEST_ARTIFACTS" >&2
  exit 1
fi

mapfile -t WDB_FILES < <(find -L "$LATEST_ARTIFACTS" -maxdepth 2 -type f -name "*.wdb" | sort)
if [[ "${#WDB_FILES[@]}" -eq 0 ]]; then
  echo "ERROR: no .wdb file found under: $LATEST_ARTIFACTS" >&2
  exit 1
fi

WDB_FILE="${WDB_FILES[0]}"
if [[ "${#WDB_FILES[@]}" -gt 1 ]]; then
  echo "WARN: multiple .wdb files found; opening first: $WDB_FILE" >&2
fi

WCFG_FILE=""
mapfile -t WCFG_FILES < <(find -L "$LATEST_ARTIFACTS" -maxdepth 1 -type f -name "*.wcfg" | sort)
if [[ "${#WCFG_FILES[@]}" -gt 0 ]]; then
  WCFG_FILE="${WCFG_FILES[0]}"
fi

# shellcheck disable=SC1090
source "$VIVADO_SETTINGS"

echo "INFO: opening WDB: $WDB_FILE"
if [[ -n "$WCFG_FILE" ]]; then
  echo "INFO: opening WCFG: $WCFG_FILE"
  vivado -mode gui -source <(printf 'open_wave_database {%s}\nopen_wave_config {%s}\n' "$WDB_FILE" "$WCFG_FILE")
else
  vivado -mode gui -source <(printf 'open_wave_database {%s}\n' "$WDB_FILE")
fi
