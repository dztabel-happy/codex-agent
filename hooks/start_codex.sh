#!/bin/bash
# Codex 一键启动器
# 用法: ./start_codex.sh <session-name> <workdir> [--full-auto]
#
# 自动完成：
# 1. 创建 tmux session
# 2. 启动 Codex TUI
# 3. 启动 pane monitor（非 full-auto 模式）
# 4. session 结束时自动清理 monitor

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SESSION="${1:?Usage: $0 <session-name> <workdir> [--full-auto]}"
WORKDIR="${2:?Usage: $0 <session-name> <workdir> [--full-auto]}"
FULL_AUTO="${3:-}"

# 检查 tmux
if ! command -v tmux &>/dev/null; then
    echo "❌ tmux not found"
    exit 1
fi

# 检查 workdir
if [ ! -d "$WORKDIR" ]; then
    echo "❌ Directory not found: $WORKDIR"
    exit 1
fi

# 杀掉同名旧 session
tmux kill-session -t "$SESSION" 2>/dev/null
pkill -f "pane_monitor.sh $SESSION" 2>/dev/null

# 构建 codex 命令
CODEX_CMD="codex --no-alt-screen"
if [ "$FULL_AUTO" = "--full-auto" ]; then
    CODEX_CMD="codex --no-alt-screen --full-auto"
fi

# 1. 创建 tmux session + 启动 Codex
tmux new-session -d -s "$SESSION" -c "$WORKDIR"
tmux send-keys -t "$SESSION" "$CODEX_CMD" Enter

# 2. 启动 pane monitor（所有模式都启动，full-auto 偶尔也会弹审批）
MONITOR_PID_FILE="/tmp/codex_monitor_${SESSION}.pid"
nohup bash "$SKILL_DIR/hooks/pane_monitor.sh" "$SESSION" > /dev/null 2>&1 &
echo $! > "$MONITOR_PID_FILE"

echo "✅ Codex started"
echo "   session:  $SESSION"
echo "   workdir:  $WORKDIR"
echo "   mode:     ${FULL_AUTO:-default-approval}"
echo "   monitor:  PID $(cat $MONITOR_PID_FILE)"
echo ""
echo "📎 tmux attach -t $SESSION    # 涛哥直接查看"
echo "🔪 tmux kill-session -t $SESSION && kill \$(cat $MONITOR_PID_FILE)  # 清理"
