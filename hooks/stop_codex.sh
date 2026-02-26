#!/bin/bash
# Codex 一键清理
# 用法: ./stop_codex.sh <session-name>

SESSION="${1:?Usage: $0 <session-name>}"
MONITOR_PID_FILE="/tmp/codex_monitor_${SESSION}.pid"

# 杀 pane monitor
if [ -f "$MONITOR_PID_FILE" ]; then
    kill "$(cat $MONITOR_PID_FILE)" 2>/dev/null
    rm -f "$MONITOR_PID_FILE"
    echo "✅ Monitor stopped"
fi
pkill -f "pane_monitor.sh $SESSION" 2>/dev/null

# 杀 tmux session
if tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux kill-session -t "$SESSION"
    echo "✅ Session $SESSION killed"
else
    echo "ℹ️ Session $SESSION not found"
fi
