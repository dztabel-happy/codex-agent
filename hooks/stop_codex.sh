#!/bin/bash
# Codex 一键清理
# 用法: ./stop_codex.sh <session-name>

set -uo pipefail

SESSION="${1:?Usage: $0 <session-name>}"
MONITOR_PID_FILE="/tmp/codex_monitor_${SESSION}.pid"

# 杀 pane monitor
if [ -f "$MONITOR_PID_FILE" ]; then
    kill "$(cat "$MONITOR_PID_FILE")" 2>/dev/null || true
    rm -f "$MONITOR_PID_FILE"
    echo "✅ Monitor stopped"
else
    echo "ℹ️ Monitor PID file not found (may have already exited)"
fi
# 兜底：按精确 session 名匹配
pkill -f "pane_monitor\\.sh ${SESSION}$" 2>/dev/null || true

# 杀 tmux session
if tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux kill-session -t "$SESSION"
    echo "✅ Session $SESSION killed"
else
    echo "ℹ️ Session $SESSION not found"
fi

# 清理日志（可选，取消注释启用）
# rm -f "/tmp/codex_monitor_${SESSION}.log"
