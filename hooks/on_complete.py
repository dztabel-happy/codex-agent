#!/usr/bin/env python3
"""
Codex notify hook — Codex 完成 turn 时：
1. 给涛哥发 Telegram 通知（看到 Codex 干了什么）
2. 唤醒 OpenClaw agent（去检查输出）
"""

import json
import subprocess
import sys
from datetime import datetime

LOG_FILE = "/tmp/codex_notify_log.txt"
TELEGRAM_CHAT_ID = "6123465134"

def log(msg: str):
    with open(LOG_FILE, "a") as f:
        f.write(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}\n")

def main() -> int:
    if len(sys.argv) < 2:
        return 0

    try:
        notification = json.loads(sys.argv[1])
    except json.JSONDecodeError as e:
        log(f"JSON parse error: {e}")
        return 1

    if notification.get("type") != "agent-turn-complete":
        return 0

    summary = notification.get("last-assistant-message", "Turn Complete!")
    cwd = notification.get("cwd", "unknown")
    thread_id = notification.get("thread-id", "unknown")

    log(f"Codex turn complete: thread={thread_id}, cwd={cwd}")
    log(f"Summary: {summary[:200]}")

    msg = (
        f"🔔 Codex 任务回复\n"
        f"📁 {cwd}\n"
        f"💬 {summary}"
    )

    # 1. 给涛哥发 Telegram 通知
    try:
        subprocess.Popen(
            [
                "openclaw", "message", "send",
                "--channel", "telegram",
                "--target", TELEGRAM_CHAT_ID,
                "--message", msg,
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        log("telegram notify fired")
    except Exception as e:
        log(f"telegram notify failed: {e}")

    # 2. 唤醒 agent（fire-and-forget）
    agent_msg = (
        f"[Codex Hook] 任务完成，请检查输出并汇报。\n"
        f"cwd: {cwd}\n"
        f"thread: {thread_id}\n"
        f"summary: {summary}"
    )
    try:
        subprocess.Popen(
            [
                "openclaw", "agent",
                "--agent", "main",
                "--message", agent_msg,
                "--deliver",
                "--channel", "telegram",
                "--timeout", "120",
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        log("agent wake fired")
    except Exception as e:
        log(f"agent wake failed: {e}")

    return 0

if __name__ == "__main__":
    sys.exit(main())
