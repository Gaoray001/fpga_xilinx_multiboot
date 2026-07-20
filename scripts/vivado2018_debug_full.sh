#!/usr/bin/env bash
set -euo pipefail

ENABLE_DEBUG=1 COMMON_VIVADO_JOBS=all ./scripts/vivado2018_common.sh full

# ENABLE_DEBUG=0 COMMON_VIVADO_JOBS=all ./scripts/vivado2018_common.sh full