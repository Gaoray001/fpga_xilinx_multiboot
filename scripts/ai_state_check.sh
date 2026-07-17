#!/usr/bin/env bash
# ai_state_check.sh — agent 工作流机械新鲜度检查（纯只读，不改任何文件）
#
# 用法：bash scripts/ai_state_check.sh
#   - agent：每轮开工前 / 收尾后各跑一次，输出贴进 report。
#   - 人工：写 prompt 前跑一遍，WARN 项即"需要在 FACT 里交代或先 commit"的事。
# 约定：只报警不拦截（恒 exit 0）；任何 WARN 都应在本轮 report / prompt 中有交代。
# 工程专有检查项放 scripts/ai_state_check.conf（可选，格式见文件）。
set -u
cd "$(dirname "$0")/.." || exit 1

TS_RE='20[0-9]{6}_[0-9]{6}'
warn_n=0
warn() { echo "WARN: $*"; warn_n=$((warn_n + 1)); }

echo "== ai_state_check $(date +%Y%m%d_%H%M%S)  branch=$(git branch --show-current 2>/dev/null || echo 非git仓库) =="

echo "-- [1] git 工作区 --"
git log -1 --format='HEAD: %h %ci %s' 2>/dev/null || warn "无法读取 git HEAD"
dirty=$(git status --short 2>/dev/null || true)
if [ -n "$dirty" ]; then
    warn "工作区非干净（构建/上板证据轮前须先 commit，或在下轮 FACT 说明）："
    echo "$dirty" | sed 's/^/    /' | head -20
else
    echo "OK: 工作区干净"
fi

echo "-- [2] 第一屏 HANDOFF_CURRENT --"
H=ai_workflow/HANDOFF_CURRENT.md
hts=""
if [ ! -f "$H" ]; then
    warn "缺少 $H"
else
    hts=$(grep -oE "$TS_RE" "$H" | head -1)
    hl=$(wc -l < "$H")
    echo "时间戳: ${hts:-无}  行数: $hl (预算 30)"
    [ "$hl" -gt 34 ] && warn "HANDOFF_CURRENT 超 30 行预算（$hl 行）——该全量重写了"
fi

echo "-- [3] 活跃任务快照 --"
state=$(grep -oE '(ai_workflow/)?tasks/[A-Za-z0-9_]+/TASK_STATE\.md' ai_workflow/TASK_INDEX.md 2>/dev/null | head -1)
if [ -z "${state:-}" ]; then
    warn "TASK_INDEX 未解析到活跃任务事实源（新工程未初始化任务时属正常）"
else
    case "$state" in ai_workflow/*) : ;; *) state="ai_workflow/$state" ;; esac
    if [ ! -f "$state" ]; then
        warn "任务总表指向的事实源不存在: $state"
    else
        sl=$(wc -l < "$state")
        echo "TASK_STATE: $state  行数: $sl (预算 150)"
        [ "$sl" -gt 155 ] && warn "TASK_STATE 超 150 行预算（$sl 行）——快照在长成日志，需清理"
        grep -qE '^本轮（|^## 本轮' "$state" && warn "TASK_STATE 出现逐轮叙事段——违反快照铁律"
        echo "唯一下一步:"
        sed -n '/^## .*唯一下一步/,/^## /p' "$state" | grep -vE '^## |^$' | head -4 | sed 's/^/    /'
    fi
fi

echo "-- [4] 最新 report vs 第一屏指针 --"
latest=$({ ls ai_workflow/tasks/*/reports/20*.md 2>/dev/null; ls reports/*/20*.md 2>/dev/null; } |
    awk -F/ '{print $NF"|"$0}' | LC_ALL=C sort | tail -1 | cut -d'|' -f2)
if [ -z "${latest:-}" ]; then
    echo "无 report（新工程属正常）"
else
    lts=$(basename "$latest" | grep -oE "$TS_RE" | head -1)
    echo "最新 report: $latest"
    if [ -n "$hts" ] && [ -n "$lts" ] && [ "$lts" \> "$hts" ]; then
        warn "HANDOFF($hts) 落后于最新 report($lts)——主线轮需记账，插叙轮需补插叙账"
    fi
    if [ -f "$H" ] && ! grep -q "$(basename "$latest")" "$H"; then
        warn "HANDOFF 未引用最新 report 文件名（$(basename "$latest")）"
    fi
fi

echo "-- [5] 未跟踪的关键文件 --"
unt=$(git status --short 2>/dev/null | grep '^??' | grep -E 'reports/|prompts/|ai_workflow/' || true)
if [ -n "$unt" ]; then
    warn "存在未跟踪的 report/prompt/状态文件（不 commit 等于没写）："
    echo "$unt" | sed 's/^/    /' | head -10
else
    echo "OK: 无未跟踪的关键文件"
fi

CONF=scripts/ai_state_check.conf
if [ -f "$CONF" ]; then
    echo "-- [6] 工程关键参数（$CONF）--"
    while IFS='|' read -r label pat file; do
        case "${label:-}" in ''|\#*) continue ;; esac
        hit=$(grep -m1 -E "$pat" "$file" 2>/dev/null | sed 's/^[[:space:]]*//')
        echo "  $label: ${hit:-未命中（$file）}"
    done < "$CONF"
fi

echo "== 结束：$warn_n 个 WARN =="
exit 0
