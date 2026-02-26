# Changelog

All notable changes to this project will be documented in this file.

## [0.2.0] - 2026-02-26

### Fixed
- `start_codex.sh`: Added `set -euo pipefail` and return code checks, no longer falsely reports success
- `pane_monitor.sh`: Fixed `if ! ... & then` syntax error causing wake failure detection to never trigger
- `on_complete.py`: Changed `stdout/stderr=PIPE` to `DEVNULL` for fire-and-forget agent wake (prevents EPIPE)
- `stop_codex.sh`: Added proper quoting for PID file reads
- `pane_monitor.sh`: PID file auto-cleanup on exit via `trap cleanup EXIT`
- `standard_task.md`: Fixed send-keys examples to use separate text and Enter (with sleep 1s)
- `knowledge_update.md`: Fixed `cache/` path to `/tmp/codex-knowledge-cache/` with auto `mkdir`
- `SKILL.md`: Updated chat ID references from hardcoded to environment variables
- `state/version.txt`: Added trailing newline

### Added
- `INSTALL.md`: Complete 7-step installation guide with troubleshooting
- `README_EN.md`: Full English README with language switcher
- Environment variable support: `CODEX_AGENT_CHAT_ID` and `CODEX_AGENT_NAME` (no code changes needed for deployment)
- `on_complete.py`: Telegram notify now checks exit code and logs stderr on failure
- `pane_monitor.sh`: Increased capture lines from 15 to 30, added more approval keywords
- `pane_monitor.sh`: Per-session log file (`/tmp/codex_monitor_<session>.log`)
- `start_codex.sh`: Pre-flight check for `codex` binary
- `stop_codex.sh`: Precise `pkill` regex to avoid killing unrelated processes
- OpenClaw session reset configuration note in README and INSTALL.md

### Changed
- All README references changed from "Agent" to "OpenClaw" for clarity
- Quick start section now points users to read `INSTALL.md` first
- Send-to-OpenClaw prompt updated to reference INSTALL.md for auto-configuration

## [0.1.0] - 2026-02-25

### Added
- Initial release
- SKILL.md: 8-step workflow engine for OpenClaw to operate Codex CLI
- Dual-channel notification: Codex notify hook (`on_complete.py`) + tmux pane monitor (`pane_monitor.sh`)
- One-click start/stop scripts (`start_codex.sh`, `stop_codex.sh`)
- Knowledge base: 6 files covering features, config schema, capabilities, prompt patterns, update protocol, changelog
- Workflows: standard task execution + knowledge base update (7-step process with 5-tier data sources)
- Two approval modes: Codex auto (`--full-auto`) or OpenClaw approval
- tmux persistence: Codex runs independent of OpenClaw turn lifecycle
