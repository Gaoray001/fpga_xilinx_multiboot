#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_NAME="$(basename "$ROOT_DIR")"
VIVADO_SETTINGS="${VIVADO_SETTINGS:-/tools/Xilinx/Vivado/2018.3/settings64.sh}"

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/vivado2018_common.sh help
  ./scripts/vivado2018_common.sh create
  ./scripts/vivado2018_common.sh open
  ./scripts/vivado2018_common.sh synth
  ./scripts/vivado2018_common.sh impl
  ./scripts/vivado2018_common.sh bit
  ./scripts/vivado2018_common.sh full
  ./scripts/vivado2018_common.sh reports
  ./scripts/vivado2018_common.sh clean-runs

Environment:
  VIVADO_SETTINGS=/tools/Xilinx/Vivado/2018.3/settings64.sh
  COMMON_VIVADO_PART_NAME=xc7vx690tffg1927-2
  COMMON_VIVADO_TOP_MODULE=Top
  COMMON_VIVADO_JOBS=all          # or an integer, e.g. 8
  ENABLE_DEBUG=1
USAGE
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

COMMAND="$1"
case "$COMMAND" in
  help|-h|--help)
    usage
    exit 0
    ;;
  create)
    TCL_SOURCE="tcl/build/01_create_project.tcl"
    ;;
  open)
    TCL_SOURCE="tcl/build/00_open_or_rebuild_project.tcl"
    ;;
  synth)
    TCL_SOURCE="tcl/build/10_synth.tcl"
    ;;
  impl)
    TCL_SOURCE="tcl/build/20_impl.tcl"
    ;;
  bit)
    TCL_SOURCE="tcl/build/30_bit.tcl"
    ;;
  full)
    TCL_SOURCE="tcl/build/40_full_build.tcl"
    ;;
  reports)
    TCL_SOURCE="tcl/build/50_reports.tcl"
    ;;
  clean-runs)
    TCL_SOURCE="tcl/build/90_clean_runs.tcl"
    ;;
  *)
    echo "ERROR: unknown command: $COMMAND" >&2
    usage
    exit 1
    ;;
esac

# 判断 工程根目录是否 存在
if [[ ! -d "$ROOT_DIR" ]]; then
  echo "ERROR: project root does not exist: $ROOT_DIR" >&2
  exit 1
fi

cd "$ROOT_DIR"

# 判断 邮件通知 设置
NOTIFY_LOCAL_ENV="$ROOT_DIR/scripts/vivado2018_notify_env.local.sh"
if [[ -f "$NOTIFY_LOCAL_ENV" ]]; then
  # shellcheck disable=SC1090
  source "$NOTIFY_LOCAL_ENV"
fi

# 判断 vivado的settings.sh 脚本文件 是否存在
if [[ ! -f "$VIVADO_SETTINGS" ]]; then
  echo "ERROR: Vivado settings file not found: $VIVADO_SETTINGS" >&2
  exit 1
fi

# 判断运行 tcl脚本文件 是否存在
if [[ ! -f "$TCL_SOURCE" ]]; then
  echo "ERROR: Tcl source file not found: $TCL_SOURCE" >&2
  exit 1
fi
TCL_SOURCE_ABS="$ROOT_DIR/$TCL_SOURCE"

RUN_STAMP="$(date +%Y%m%d_%H%M%S)"
RUN_NAME="${RUN_STAMP}_${COMMAND}"
RUN_DIR="$ROOT_DIR/_runs/common_vivado/$RUN_NAME"
REPORTS_DIR="$RUN_DIR/reports"
ARTIFACTS_DIR="$ROOT_DIR/_artifacts/common_vivado/$RUN_NAME"
LOGS_DIR="$RUN_DIR/logs"
WORK_DIR="$RUN_DIR/work"
LATEST_LINK="$ROOT_DIR/_runs/latest"
mkdir -p "$REPORTS_DIR" "$ARTIFACTS_DIR" "$LOGS_DIR" "$WORK_DIR"

COMMAND_FILE="$RUN_DIR/command.txt"
SUMMARY_FILE="$RUN_DIR/summary.txt"
STATUS_FILE="$RUN_DIR/status.txt"
VIVADO_LOG="$RUN_DIR/vivado.log"
VIVADO_JOU="$RUN_DIR/vivado.jou"
STARTED_AT="$(date '+%Y-%m-%d %H:%M:%S')"

{
  echo "command: ./scripts/vivado2018_common.sh $COMMAND"
  echo "root: $ROOT_DIR"
  echo "project_name: $PROJECT_NAME"
  echo "part_name: ${COMMON_VIVADO_PART_NAME:-xc7vx690tffg1927-2}"
  echo "top_module: ${COMMON_VIVADO_TOP_MODULE:-Top}"
  echo "vivado_jobs: ${COMMON_VIVADO_JOBS:-default}"
  echo "tcl: $TCL_SOURCE"
  echo "started: $STARTED_AT"
  echo "run_dir: $RUN_DIR"
  echo "reports_dir: $REPORTS_DIR"
  echo "artifacts_dir: $ARTIFACTS_DIR"
  echo "logs_dir: $LOGS_DIR"
  echo "work_dir: $WORK_DIR"
} > "$COMMAND_FILE"

{
  echo "command: $COMMAND"
  echo "root: $ROOT_DIR"
  echo "project_name: $PROJECT_NAME"
  echo "part_name: ${COMMON_VIVADO_PART_NAME:-xc7vx690tffg1927-2}"
  echo "top_module: ${COMMON_VIVADO_TOP_MODULE:-Top}"
  echo "vivado_jobs: ${COMMON_VIVADO_JOBS:-default}"
  echo "tcl: $TCL_SOURCE"
  echo "run_dir: $RUN_DIR"
  echo "reports_dir: $REPORTS_DIR"
  echo "artifacts_dir: $ARTIFACTS_DIR"
  echo "logs_dir: $LOGS_DIR"
  echo "work_dir: $WORK_DIR"
  echo "vivado_log: $VIVADO_LOG"
  echo "vivado_journal: $VIVADO_JOU"
} > "$SUMMARY_FILE"

{
  echo "action=$COMMAND"
  echo "started=$STARTED_AT"
  echo "run_dir=$RUN_DIR"
  echo "latest=$LATEST_LINK"
  echo "reports_dir=$REPORTS_DIR"
  echo "artifacts_dir=$ARTIFACTS_DIR"
  echo "logs_dir=$LOGS_DIR"
  echo "work_dir=$WORK_DIR"
} > "$STATUS_FILE"

source "$VIVADO_SETTINGS"

if ! command -v vivado >/dev/null 2>&1; then
  echo "ERROR: vivado command not found after sourcing $VIVADO_SETTINGS" >&2
  exit 1
fi

export COMMON_VIVADO_RUN_DIR="$RUN_DIR"
export COMMON_VIVADO_ROOT_DIR="$ROOT_DIR"
export COMMON_VIVADO_PROJECT_NAME="$PROJECT_NAME"
export COMMON_VIVADO_PART_NAME="${COMMON_VIVADO_PART_NAME:-xc7vx690tffg1927-2}"
export COMMON_VIVADO_TOP_MODULE="${COMMON_VIVADO_TOP_MODULE:-Top}"
export COMMON_VIVADO_JOBS="${COMMON_VIVADO_JOBS:-}"
export COMMON_VIVADO_REPORTS_DIR="$REPORTS_DIR"
export COMMON_VIVADO_ARTIFACTS_DIR="$ARTIFACTS_DIR"
export COMMON_VIVADO_LOGS_DIR="$LOGS_DIR"
export COMMON_VIVADO_WORK_DIR="$WORK_DIR"


#################################################################################
# cd  _runs/common_vivado/2026xxxx_083327_impl
# $TCL_SOURCE_ABS : 对应的tcl脚本呢
# 执行 vivado -mode batch -source 
# -notrace：让 Tcl 脚本在运行时不要把每一行命令都打印到终端，保持日志清爽
# -journal ... -log ...：将 Vivado 默认瞎扔的日志文件重定向到我们指定的带时间戳的目录下
# STATUS=$?：获取上一个命令的退出状态码
################################################################################
set +e
cd "$RUN_DIR"
vivado -mode batch -source "$TCL_SOURCE_ABS" -notrace -journal "$VIVADO_JOU" -log "$VIVADO_LOG"
STATUS=$?
set -e
FINISHED_AT="$(date '+%Y-%m-%d %H:%M:%S')"

if [[ "$STATUS" -eq 0 ]]; then
  RESULT="SUCCESS"
else
  RESULT="FAILED"
fi

################################################################################
# 软链接
# - 已经存在软链接,则将 common_vivado/$RUN_NAME 链接 $LATEST_LINK
# - 存在同名文件或真实文件夹，将文件夹备份，再软链接
# - 全新的软链接
################################################################################

if [[ -L "$LATEST_LINK" ]]; then
  ln -sfn "common_vivado/$RUN_NAME" "$LATEST_LINK"
elif [[ -e "$LATEST_LINK" ]]; then
  mv "$LATEST_LINK" "$ROOT_DIR/_runs/latest.bak_$RUN_STAMP"
  ln -s "common_vivado/$RUN_NAME" "$LATEST_LINK"
else
  ln -s "common_vivado/$RUN_NAME" "$LATEST_LINK"
fi

SYNTH_STATUS="unknown"
IMPL_STATUS="unknown"
BITSTREAM_FOUND="0"
if [[ -f "$STATUS_FILE" ]]; then
  SYNTH_STATUS="$(awk -F= '$1=="tcl_synth_status"{print $2}' "$STATUS_FILE" | tail -1)"
  IMPL_STATUS="$(awk -F= '$1=="tcl_impl_status"{print $2}' "$STATUS_FILE" | tail -1)"
  BITSTREAM_FOUND="$(awk -F= '$1=="tcl_bitstream_found"{print $2}' "$STATUS_FILE" | tail -1)"
fi
SYNTH_STATUS="${SYNTH_STATUS:-unknown}"
IMPL_STATUS="${IMPL_STATUS:-unknown}"
BITSTREAM_FOUND="${BITSTREAM_FOUND:-0}"

{
  echo "finished: $FINISHED_AT"
  echo "exit_status: $STATUS"
} >> "$SUMMARY_FILE"

echo "result: $RESULT" >> "$SUMMARY_FILE"
echo "latest: $LATEST_LINK -> common_vivado/$RUN_NAME" >> "$SUMMARY_FILE"

{
  echo "finished=$FINISHED_AT"
  echo "exit_status=$STATUS"
  echo "result=$RESULT"
  echo "latest_target=common_vivado/$RUN_NAME"
  echo "synth_status=$SYNTH_STATUS"
  echo "impl_status=$IMPL_STATUS"
  echo "bitstream_found=$BITSTREAM_FOUND"
} >> "$STATUS_FILE"

NOTIFY_ENABLE="${BUILD_NOTIFY_ENABLE:-0}"
NOTIFY_SUBJECT_PREFIX="${BUILD_NOTIFY_SUBJECT_PREFIX:-[Vivado dev-k7]}"
NOTIFY_BODY_FILE="$RUN_DIR/notify_body.txt"

if [[ "$NOTIFY_ENABLE" == "1" ]]; then
  if [[ -z "${BUILD_NOTIFY_EMAIL:-}" ]]; then
    echo "INFO: BUILD_NOTIFY_ENABLE=1 but BUILD_NOTIFY_EMAIL is not set; skip mail notification."
  elif [[ -x "$HOME/bin/send_notify_mail" ]]; then
    {
      echo "Action: $COMMAND"
      echo "Result: $RESULT"
      echo "Exit status: $STATUS"
      echo "Run directory: $RUN_DIR"
      echo "Latest: $LATEST_LINK -> common_vivado/$RUN_NAME"
      echo "Vivado log: $VIVADO_LOG"
      echo "Vivado journal: $VIVADO_JOU"
      echo "Summary: $SUMMARY_FILE"
      echo "Artifacts: $ARTIFACTS_DIR"
      echo "Reports: $REPORTS_DIR"
      echo "Synthesis status: $SYNTH_STATUS"
      echo "Implementation status: $IMPL_STATUS"
      echo "Bitstream found: $BITSTREAM_FOUND"
    } > "$NOTIFY_BODY_FILE"
    "$HOME/bin/send_notify_mail" "$BUILD_NOTIFY_EMAIL" "$NOTIFY_SUBJECT_PREFIX $COMMAND $RESULT" "$NOTIFY_BODY_FILE" || true
  else
    echo "INFO: BUILD_NOTIFY_ENABLE=1 and BUILD_NOTIFY_EMAIL is set, but $HOME/bin/send_notify_mail is not executable; skip mail notification."
  fi
else
  echo "INFO: BUILD_NOTIFY_ENABLE is not 1; skip notify."
fi

echo "Vivado command: $COMMAND"
echo "Result: $RESULT"
echo "Run directory: $RUN_DIR"
echo "Latest: $LATEST_LINK -> common_vivado/$RUN_NAME"
echo "Vivado log: $VIVADO_LOG"
echo "Vivado journal: $VIVADO_JOU"
echo "Summary: $SUMMARY_FILE"

exit "$STATUS"
