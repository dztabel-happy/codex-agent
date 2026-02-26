# Codex Agent 安装与配置指南

> 完整的手把手配置流程。也可以把本文件内容发给 OpenClaw，让它自动帮你配置。

## 前提条件

- [OpenClaw](https://github.com/openclaw/openclaw) 已安装并运行（`openclaw gateway status` 显示 running）
- [Codex CLI](https://github.com/openai/codex) 已安装（`codex --version`）
- tmux 已安装（`tmux -V`）
- Telegram 已配置为 OpenClaw 消息通道

## 第一步：安装 Skill

将 codex-agent 放到 OpenClaw 的 skills 目录：

```bash
# 方式 1：git clone
cd ~/.openclaw/workspace/skills/
git clone https://github.com/dztabel-happy/codex-agent.git

# 方式 2：手动复制（如果你已经下载了）
cp -r /path/to/codex-agent ~/.openclaw/workspace/skills/codex-agent
```

验证 skill 被识别：
```bash
ls ~/.openclaw/workspace/skills/codex-agent/SKILL.md
# 应该存在
```

## 第二步：配置 Codex notify hook

编辑 Codex 配置文件 `~/.codex/config.toml`，添加 notify 字段：

```toml
notify = ["python3", "<SKILL_PATH>/hooks/on_complete.py"]
```

其中 `<SKILL_PATH>` 替换为实际路径，例如：
```toml
notify = ["python3", "/Users/你的用户名/.openclaw/workspace/skills/codex-agent/hooks/on_complete.py"]
```

## 第三步：配置通知目标

有两种方式设置 Telegram Chat ID 和 agent 名称：

### 方式 A：环境变量（推荐，不改代码）

在你的 `~/.zshrc` 或 `~/.bashrc` 中添加：

```bash
export CODEX_AGENT_CHAT_ID="你的Telegram_Chat_ID"
export CODEX_AGENT_NAME="main"  # OpenClaw agent 名称，通常是 main
```

然后 `source ~/.zshrc`。

获取 Chat ID 的方法：给你的 OpenClaw Telegram bot 发一条消息，然后查看 OpenClaw 日志中的 chat_id。

### 方式 B：直接修改代码

编辑 `hooks/on_complete.py`，修改：
```python
TELEGRAM_CHAT_ID = os.environ.get("CODEX_AGENT_CHAT_ID", "你的Chat_ID")
```

编辑 `hooks/pane_monitor.sh`，修改：
```bash
CHAT_ID="${CODEX_AGENT_CHAT_ID:-你的Chat_ID}"
```

## 第四步：配置 OpenClaw session 重置

⚠️ **必须做**。OpenClaw 默认每天凌晨 4 点自动重置 session，会导致 Codex 长任务完成后 hook 唤醒 OpenClaw 时上下文全丢。

编辑 `~/.openclaw/openclaw.json`，添加或修改：

```json
{
  "session": {
    "reset": {
      "mode": "idle",
      "idleMinutes": 52560000
    }
  }
}
```

这相当于设置 100 年后才重置（OpenClaw 没有 `mode: "off"` 选项）。你仍然可以随时用 `/new` 手动重置。

然后重启 gateway：
```bash
openclaw gateway restart
```

## 第五步：设置脚本权限

```bash
cd ~/.openclaw/workspace/skills/codex-agent/hooks/
chmod +x on_complete.py pane_monitor.sh start_codex.sh stop_codex.sh
```

## 第六步：验证安装

依次运行以下命令，确保每一步都成功：

```bash
# 1. Codex 可用
codex --version

# 2. tmux 可用
tmux -V

# 3. Telegram 通知可发送（替换 YOUR_CHAT_ID）
openclaw message send --channel telegram --target YOUR_CHAT_ID --message "✅ codex-agent 通知测试"

# 4. OpenClaw agent 可唤醒
openclaw agent --agent main --message "✅ codex-agent 唤醒测试" --deliver --channel telegram --timeout 10

# 5. Codex notify hook 可触发（在任意 git 目录下）
cd /tmp && mkdir -p codex-test && cd codex-test && git init
codex exec "say hello"
# 你应该在 Telegram 上收到通知
```

## 第七步：使用

安装完成后，直接在 Telegram 里对 OpenClaw 说：

> "用 Codex 帮我在 /path/to/project 实现 XX 功能"

OpenClaw 会：
1. 理解你的需求
2. 设计提示词
3. 在 tmux 里启动 Codex
4. 中间过程自动处理
5. 完成后 Telegram 通知你

你随时可以 `tmux attach -t <session>` 接入查看。

---

## 一键自动配置（发给 OpenClaw）

如果你不想手动配置，把下面这段话发给 OpenClaw，它会自动帮你完成配置：

```
请帮我安装和配置 codex-agent skill。步骤：
1. 将 codex-agent skill 安装到 ~/.openclaw/workspace/skills/codex-agent/
2. 在 ~/.codex/config.toml 中添加 notify hook，路径指向 hooks/on_complete.py
3. 设置环境变量 CODEX_AGENT_CHAT_ID 为我的 Telegram Chat ID
4. 配置 OpenClaw session 不自动重置（idle + 52560000 分钟）
5. 设置脚本执行权限
6. 运行验证测试确认所有组件正常
安装指南在 skills/codex-agent/INSTALL.md
```

## 故障排查

| 症状 | 检查 |
|------|------|
| Codex 完成后没收到通知 | 检查 `~/.codex/config.toml` 的 notify 路径是否正确 |
| 收到通知但 OpenClaw 没反应 | 检查 `openclaw agent --agent main` 是否可用 |
| pane monitor 没检测到审批 | 查看 `/tmp/codex_monitor_<session>.log` |
| start_codex.sh 报错 | 检查 tmux 和 codex 是否安装，workdir 是否存在 |
| `--full-auto` 报冲突 | 检查 `~/.zshrc` 是否有 codex alias |
