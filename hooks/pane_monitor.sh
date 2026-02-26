#!/bin/bash
# Codex TUI pane 监控器
# 用法: ./pane_monitor.sh <tmux-session-name>
# 后台运行，检测审批等待和任务完成，发送通知

SESSION="${1:?Usage: $0 <tmux-session-name>}"
CHAT_ID="6123465134"
CHECK_INTERVAL=5  # 秒
LAST_STATE=""
NOTIFIED_APPROVAL=""

log() { echo "[$(date '+%H:%M:%S')] $1" >> /tmp/codex_monitor.log; }

log "Monitor started for session: $SESSION"

while true; do
    # 检查 session 是否存在
    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        log "Session $SESSION gone, exiting"
        exit 0
    fi

    OUTPUT=$(tmux capture-pane -t "$SESSION" -p -S -15 2>/dev/null)

    # 检测审批等待
    if echo "$OUTPUT" | grep -q "Would you like to run\|Press enter to confirm"; then
        # 提取要执行的命令
        CMD=$(echo "$OUTPUT" | grep '^\s*\$' | tail -1 | sed 's/^\s*\$ //')
        STATE="approval:$CMD"

        if [ "$STATE" != "$NOTIFIED_APPROVAL" ]; then
            NOTIFIED_APPROVAL="$STATE"
            MSG="⏸️ Codex 等待审批
📋 命令: ${CMD:-unknown}
🔧 session: $SESSION"
            # 1. 通知涛哥
            openclaw message send --channel telegram --target "$CHAT_ID" --message "$MSG" --silent 2>/dev/null &
            # 2. 唤醒 agent
            AGENT_MSG="[Codex Monitor] 审批等待，请处理。
session: $SESSION
command: ${CMD:-unknown}
请 tmux send-keys -t $SESSION '1' Enter 批准，或 '3' Enter 拒绝。"
            openclaw agent --agent main --message "$AGENT_MSG" --deliver --channel telegram --timeout 120 2>/dev/null &
            log "Approval detected: $CMD"
        fi

    # 检测回到空闲（任务完成，? for shortcuts 出现）
    elif echo "$OUTPUT" | grep -q "? for shortcuts"; then
        if [ "$LAST_STATE" = "working" ]; then
            LAST_STATE="idle"
            NOTIFIED_APPROVAL=""
            # notify hook 已经处理 turn complete，这里不重复通知
            log "Back to idle"
        fi

    # 检测正在工作
    elif echo "$OUTPUT" | grep -q "esc to interrupt\|Thinking\|Creating\|Editing\|Running"; then
        LAST_STATE="working"
    fi

    sleep "$CHECK_INTERVAL"
done
