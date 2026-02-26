# Codex Agent — Let OpenClaw Operate Codex for You 🧠

**English** | [中文](README.md)

> Lie in bed, say one sentence, and OpenClaw will launch Codex, craft prompts, handle approvals, check quality, and report results. You can jump into the terminal anytime.

**This is an [OpenClaw](https://github.com/openclaw/openclaw)-exclusive Skill.** It requires OpenClaw as the AI agent runtime, leveraging its agent wake-up, message delivery, and cron capabilities to drive the entire workflow.

## What Is It?

In one sentence: **OpenClaw operates Codex CLI on behalf of the user.**

Codex is OpenAI's terminal coding tool. It's powerful, but requires you to sit at your computer — writing prompts, watching output, approving commands, checking results. This skill lets OpenClaw do all of that for you.

It comes down to two things: **tmux + hooks**.

- **tmux**: Codex runs in a tmux session. OpenClaw reads output and sends commands through tmux — exactly like a human would in the terminal
- **hooks**: When Codex finishes a task or waits for approval, it automatically notifies the user (Telegram) + wakes up OpenClaw to handle it

You can `tmux attach` at any time to see what Codex is doing, or even take over.

## Full-Power Codex

Normal usage: you manually write a prompt and send it to Codex. Codex only knows what you tell it.

With this skill, OpenClaw does the following **before** sending a task to Codex:

1. **Scans the local environment**: Which MCP servers are installed (Exa search, Chrome control, etc.), which Skills, which models are available
2. **Selects the right model**: Fast model for simple bugs, powerful model for architecture design, code-specific model for code search
3. **Crafts the prompt**: Not forwarding the user's raw message, but constructing an optimal prompt based on the knowledge base + prompt pattern library — telling Codex what tools it can use, how to break down the task, what format to output
4. **Enables appropriate feature flags**: Such as `multi_agent`, `web_search`, `shell_snapshot`, etc., enabled as needed

This means Codex receives a **carefully designed task that fully utilizes all local capabilities**, not a casual one-liner from the user.

## What Problem Does It Solve?

Normal Codex workflow:

```
Sit at computer → Open terminal → Think about prompt → Start Codex → Watch output →
Approve commands → Not satisfied? Start over → Done
```

With this skill:

```
Lie in bed → Tell OpenClaw in Telegram "Add XX feature to this project" →
OpenClaw starts Codex → Handles everything in between → Notifies you on Telegram when done →
Not satisfied? Say one sentence to continue → Want to watch? tmux attach for live view
```

**Core value: User is the boss, OpenClaw is the employee, Codex is the tool.**

## Workflow

```
1. User gives task (Telegram / terminal / any channel)
     ↓
2. OpenClaw understands requirements, asks clarifying questions
     ↓
3. OpenClaw designs prompt, selects execution mode, confirms with user
     ↓
4. OpenClaw launches Codex in tmux
     ↓
5. Codex works, OpenClaw gets woken up via hooks:
   ├── Task complete → OpenClaw checks output quality
   │   ├── Satisfied → Notifies user on Telegram with results
   │   └── Not satisfied → Tells Codex to keep working
   ├── Waiting for approval → OpenClaw decides approve/reject
   └── Directional issue → Immediately asks user for confirmation
     ↓
6. User receives final result
   (can tmux attach at any point during the process)
```

OpenClaw handles the entire process autonomously, but **every step is simultaneously sent to Telegram** — task completion, approval requests, output content — all visible on your phone in real time. You can choose to ignore it (let OpenClaw handle it) or jump in and intervene at any time.

## How It Works: tmux + hooks

### tmux: Operating the Terminal Like a Human

OpenClaw operates Codex exactly like a human would:

```bash
# Start Codex (same as typing in terminal)
tmux send-keys -t codex-session 'codex --full-auto' Enter

# Send prompt (same as typing)
tmux send-keys -t codex-session 'Implement XX feature'
sleep 1
tmux send-keys -t codex-session Enter

# Check output (same as looking at the screen)
tmux capture-pane -t codex-session -p
```

Benefits of tmux:
- **Not limited by OpenClaw turn timeout**: Codex can run as long as needed; OpenClaw checks in when woken up
- **User can join anytime**: `tmux attach -t codex-session` to see real-time output
- **Persistent**: OpenClaw restart, network disconnect — Codex keeps running

### Hooks: Automatic Notifications for Task Completion and Approval Requests

Two mechanisms cover two types of events:

**1. Codex notify hook (task completion)**

Codex's built-in `notify` config calls a script when a task is done:

```
Codex completes turn → on_complete.py
                       ├── 📱 Telegram notifies user (full Codex reply)
                       └── 🤖 Wakes OpenClaw (auto-checks output)
```

Users see Codex's complete reply on Telegram — essentially real-time monitoring.

**2. tmux pane monitor (approval requests)**

Codex's notify doesn't cover approval scenarios, so `pane_monitor.sh` monitors tmux output:

```
Codex shows approval prompt → pane_monitor.sh detects keywords
                              ├── 📱 Telegram notifies user (specific command awaiting approval)
                              └── 🤖 Wakes OpenClaw (auto-decides approve/reject)
```

Both mechanisms **trigger dual channels simultaneously**: user and OpenClaw both receive the message. User can ignore it (OpenClaw will handle it) or reply directly to intervene.

### User Can Take Over Anytime

This is not a black box. At any time:

- `tmux attach -t codex-session`: See exactly what Codex is doing
- Type directly in tmux: Take over operation
- `tmux detach`: Done watching, hand back to OpenClaw

## Two Approval Modes

User chooses before launch:

| Mode | Who Approves | Use Case |
|------|-------------|----------|
| **Codex auto** (`--full-auto`) | Codex decides | Routine dev, hands-off |
| **OpenClaw approves** (default) | OpenClaw decides approve/reject | Sensitive ops, need oversight |

Pane monitor runs in both modes (`--full-auto` occasionally still prompts for approval).

## Knowledge Base: OpenClaw Truly Understands Codex

OpenClaw doesn't blindly forward commands. It maintains a Codex knowledge base:

| File | Content |
|------|---------|
| `features.md` | 30+ feature flags, slash commands, CLI subcommands |
| `config_schema.md` | Complete config.toml field definitions |
| `capabilities.md` | Local MCP/Skills/model capabilities |
| `prompting_patterns.md` | Prompt pattern library (by task type) |
| `UPDATE_PROTOCOL.md` | 5-tier data source update protocol |
| `changelog.md` | Version changes + findings from testing |

The knowledge base gets stale, so there's an update protocol: triggered by version change / >7 days / manual request, updating from CLI introspection → Schema → GitHub → Official docs → Community sources.

## File Structure

```
codex-agent/
├── SKILL.md                    # OpenClaw workflow instructions (for OpenClaw to read)
├── README.md                   # Chinese docs (for humans)
├── README_EN.md                # English docs (this file)
├── INSTALL.md                  # Installation guide (7 steps)
│
├── hooks/
│   ├── on_complete.py          # Codex done → Telegram + wake OpenClaw
│   ├── pane_monitor.sh         # Approval detection → Telegram + wake OpenClaw
│   ├── start_codex.sh          # One-click start (Codex + monitor)
│   └── stop_codex.sh           # One-click cleanup
│
├── knowledge/                  # Codex knowledge base (6 files)
├── workflows/                  # Detailed workflows
├── references/                 # CLI command reference
└── state/                      # Runtime state (version, last updated)
```

## Quick Start

See **[INSTALL.md](INSTALL.md)** for detailed setup (7 steps, ~5 minutes).

Or, send this message to your OpenClaw and it will auto-configure everything:

> Please install and configure the codex-agent skill.
> First read the full installation guide at `~/.openclaw/workspace/skills/codex-agent/INSTALL.md`, then follow the steps to complete the setup.
> If the file doesn't exist yet, first clone from https://github.com/dztabel-happy/codex-agent to `~/.openclaw/workspace/skills/codex-agent/`, then read INSTALL.md and execute.

After setup, just say something to OpenClaw in Telegram:

> "Use Codex to add XX feature to /path/to/project"

## Prerequisites

- [OpenClaw](https://github.com/openclaw/openclaw) installed and running
- [Codex CLI](https://github.com/openai/codex) installed
- tmux installed
- Telegram configured as OpenClaw message channel
- ⚠️ **OpenClaw session auto-reset must be disabled or extended** (default daily reset loses Codex task context, see [INSTALL.md](INSTALL.md))

## Known Issues & Workarounds

| Issue | Solution |
|-------|----------|
| OpenClaw daily session reset loses long task context | Disable auto-reset (see INSTALL.md) |
| tmux send-keys text + Enter together, Codex unresponsive | Send separately with sleep 1s in between |
| `--full-auto` conflicts with shell alias | Check `~/.bashrc` / `~/.zshrc` for codex aliases |
| Codex notify doesn't cover approval waits | pane_monitor.sh fills the gap |
| `--full-auto` occasionally still prompts | pane monitor runs in all modes |
| Codex memories don't work | `disable_response_storage = true` + custom provider incompatible |
| Notify payload missing field docs | `turn-id` and `cwd` discovered through testing |

## Roadmap

- [ ] Port pattern to Claude Code / OpenCode agent
- [ ] Add more prompt patterns (code review, architecture design)
- [ ] pane monitor: detect more approval patterns
