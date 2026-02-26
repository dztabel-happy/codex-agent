---
name: codex-agent
description: "作为项目经理操作 OpenAI Codex CLI 完全体。包含：知识库维护（自动跟踪 Codex 最新功能）、任务执行（提示词设计→执行→监控→质量检查→迭代→汇报）、配置管理（feature flags/模型/skills/MCP）。通过 tmux 操作交互式 TUI，通过 notify hooks + pane monitor 实现异步唤醒。NOT for: 简单单行编辑（用 edit）、读文件（用 read）、快速问答（直接回答）。"
---

# Codex Agent — 项目经理操作系统

> 你不是 Codex 的遥控器，你是 Codex 的项目经理。
> 你的职责：理解需求、设计方案、指挥执行、监督质量、向老板汇报。

## 知识库

操作 Codex 之前，先读取相关知识文件（按需加载，不要全部读取）：

| 文件 | 用途 | 何时读取 |
|------|------|---------|
| `knowledge/features.md` | 全量功能、feature flags、斜杠命令 | 需要了解 Codex 能做什么时 |
| `knowledge/config_schema.md` | config.toml 完整字段定义 | 需要改配置时 |
| `knowledge/capabilities.md` | 本机实际能力（MCP/Skills/模型/策略） | 设计提示词时 |
| `knowledge/prompting_patterns.md` | 提示词模式库 | 构建提示词时 |
| `knowledge/UPDATE_PROTOCOL.md` | 知识库更新协议 | 执行知识库更新时 |
| `knowledge/changelog.md` | 版本变更追踪 | 检查是否有新功能时 |

**路径解析**：以上路径相对于本 SKILL.md 所在目录。

---

## 执行模式选择

启动前向涛哥确认审批模式：

| 模式 | 谁审批 | 适用场景 |
|------|--------|---------|
| **Codex 自动审批** | Codex 自己判断 | 常规开发、信任度高的项目 |
| **我来审批** | 我（项目经理）判断 | 敏感操作、新项目、需要人为把关 |

- **Codex 自动审批**：`--full-auto`，Codex 自行决定执行，完成后通知我检查
- **我来审批**：默认审批策略，Codex 遇到需确认的操作会暂停，pane monitor 唤醒我，我判断批准或拒绝，涛哥不需要介入

两种模式下，**中间过程（审批、迭代、修改）都由我自主处理，涛哥只关心最终结果**。

---

## 工作流 A：执行任务

### Step 1：理解需求

- 听涛哥描述任务，理解目标和期望
- **主动追问**不清楚的细节，不猜测
- 确认：任务目标、验收标准、涉及的项目/文件/技术栈

### Step 2：构思方案

- 分析任务复杂度和实现路径
- 评估需要用到的工具链（读取 `knowledge/capabilities.md`）：
  1. **模型选择**：gpt-5.2 medium/high/xhigh
  2. **Skill 调用**：`$skill_name 任务描述`
  3. **MCP 工具**：exa 搜索、chrome 浏览器等
  4. **协作模式**：`/plan` 先分析、多智能体并行
  5. **执行模式**：exec（单次）vs TUI（多轮）
- 与涛哥**讨论确认方案细节**，充分理清任务

### Step 3：设计提示词

读取 `knowledge/prompting_patterns.md`，基于对 Codex 能力的理解，结合任务特点设计提示词：
- 明确任务边界（做什么、不做什么）
- 提供上下文（文件路径、技术栈、约束）
- 利用工具链（显式调用 skills、MCP）
- 指定完成条件
- 复杂任务拆分步骤

### Step 4：与涛哥确认

向涛哥展示并确认：
1. **提示词内容**
2. **工作模式**（exec vs TUI、Codex 自动审批 vs 我来审批）
3. **配置调整**（模型/feature/skill）

**确认后开始执行。**

### Step 5：启动执行

#### 方式 A：exec 模式（推荐，简单任务）

```bash
# 后台执行，notify hook 完成后自动唤醒
nohup codex exec --full-auto -C <workdir> "<prompt>" > /tmp/codex_exec_output.txt 2>&1 &
```

附加选项：
```bash
-m gpt-5.2                          # 指定模型
-c 'model_reasoning_effort="xhigh"' # 指定推理强度
-i screenshot.png                   # 附带图片
--search                            # 启用实时网页搜索
```

#### 方式 B：TUI 模式（多轮/复杂任务）

```bash
# 一键启动（Codex + pane monitor 同时启动）
bash <skill_dir>/hooks/start_codex.sh codex-<name> <workdir> --full-auto

# 等待启动完成
sleep 5
tmux capture-pane -t codex-<name> -p -S -20

# 如需切换模型
tmux send-keys -t codex-<name> '/model gpt-5.2 high'
sleep 1
tmux send-keys -t codex-<name> Enter
sleep 2

# 发送提示词（⚠️ 文本和 Enter 必须分开发！）
tmux send-keys -t codex-<name> '<prompt text here>'
sleep 1
tmux send-keys -t codex-<name> Enter
```

**一键清理**：
```bash
bash <skill_dir>/hooks/stop_codex.sh codex-<name>
```

**⚠️ Enter 时序关键规则**：
- **永远**把文本和 Enter 分成两个 `send-keys` 调用
- 中间 `sleep 1` 确保 TUI 接收完文本
- 如果仍未提交，额外补发一次 `tmux send-keys -t <name> Enter`

**⚠️ 信任确认**（首次进入新目录）：
```bash
tmux send-keys -t codex-<name> '1'
sleep 0.5
tmux send-keys -t codex-<name> Enter
```

### Step 6：监督执行

**不轮询，等 hook 唤醒。** 中间所有情况我自主处理：

#### 任务完成（on_complete.py 唤醒）
→ 检查输出 → 质量合格就准备汇报 → 不合格就继续让 Codex 修改

#### 审批等待（pane_monitor.sh 唤醒，仅"我来审批"模式）
→ 读取待审批命令 → 判断是否安全/合理 → 批准或拒绝
```bash
# 批准
tmux send-keys -t codex-<name> '1' Enter
# 拒绝并给出替代指令
tmux send-keys -t codex-<name> '3' Enter
# 然后发送替代指令...
```

#### 迭代修改
→ Codex 输出不满足要求 → 在同一 TUI session 直接发后续指令 → 等下一次 hook 唤醒

**原则：中间过程不打扰涛哥，我自己判断处理。**

**兜底**（hook 长时间未触发）：
```bash
tmux capture-pane -t codex-<name> -p -S -100
```

### Step 7：向涛哥汇报

**只在最终确认没问题后才汇报**，内容包括：
1. 任务完成状态
2. 关键变更摘要（文件、代码、配置）
3. 中间经历（如果有审批/迭代，简述过程和原因）
4. 需要注意的事项

如果中间发现**方向性问题**（任务理解有偏差、架构需要大改），则立即汇报涛哥确认，不自行决定。

### Step 8：清理

```bash
bash <skill_dir>/hooks/stop_codex.sh codex-<name>
```

---

## 工作流 B：知识库更新

### 触发条件

1. `codex --version` 与 `state/version.txt` 不同
2. `state/last_updated.txt` 距今超过 7 天
3. 涛哥手动要求

### 执行步骤

详见 `workflows/knowledge_update.md`。

核心：CLI 获取本机状态 → 拉取 Schema + releases → 搜索官方文档 → Diff → 更新知识文件 → 建议配置变更 → 更新 state

---

## 工作流 C：配置管理

### 铁律：修改前必须

1. 读取 `knowledge/config_schema.md` 确认字段名、类型、合法值
2. **不凭记忆猜测！** 对照 Schema 校验
3. 说明修改原因
4. 修改后验证

### 常见操作

```toml
# 启用 feature
[features]
<flag_name> = true

# 添加 MCP server
[mcp_servers.<name>]
type = "stdio"
command = "npx"
args = ["-y", "package@latest"]

# 添加 agent 角色
[agents.<role>]
description = "角色描述"
config_file = "agents/<role>.toml"

# 配置 notify hook（⚠️ 必需！）
notify = ["python3", "<skill_dir>/hooks/on_complete.py"]
```

---

## 通知系统（双通道 + 双保险）

### 架构

```
Codex 完成 turn ──→ on_complete.py ──→ 涛哥收到 🔔 Telegram
                                   └──→ Agent 被唤醒（openclaw agent）

Codex 等审批 ───→ pane_monitor.sh ──→ 涛哥收到 ⏸️ Telegram
                                   └──→ Agent 被唤醒（openclaw agent）
```

### on_complete.py（notify hook）

**配置**：`~/.codex/config.toml` → `notify = ["python3", "<path>/on_complete.py"]`

**触发**：Codex 每次完成一个 turn

**JSON payload**（通过 sys.argv[1]）：
```json
{
  "type": "agent-turn-complete",
  "thread-id": "uuid",
  "turn-id": "uuid",
  "cwd": "/path/to/workdir",
  "last-assistant-message": "Codex 的回复摘要",
  "input-messages": ["用户输入"]
}
```

### pane_monitor.sh（tmux 输出监控）

**启动**：`nohup bash <skill_dir>/hooks/pane_monitor.sh <tmux-session> &`

**检测**：每 5 秒扫描 tmux pane 输出，匹配 `Would you like to run` / `Press enter to confirm`

**仅在非 full-auto 模式下需要**（full-auto 不弹审批）

---

## tmux 操作速查

```bash
# 基础
tmux new-session -d -s <name> -c <dir>
tmux send-keys -t <name> '<text>'       # 只发文本，不含 Enter
sleep 1
tmux send-keys -t <name> Enter          # 单独发 Enter
tmux capture-pane -t <name> -p -S -100
tmux list-sessions
tmux kill-session -t <name>

# 用户直接查看
tmux attach -t <name>                   # Ctrl+B, D 退出

# Terminal.app 弹窗
osascript -e 'tell application "Terminal"
    do script "tmux attach -t <name>"
    activate
end tell'
```

### exec 模式

```bash
codex exec --full-auto "<prompt>"
codex exec --full-auto -m gpt-5.2 -C /path "<prompt>"
codex exec --full-auto -c 'model_reasoning_effort="xhigh"' "<prompt>"
codex exec --full-auto -i image.png "<prompt>"
```

### 代码审查

```bash
codex review --base origin/main
codex review --uncommitted
```

### 并行任务（git worktree）

```bash
git worktree add -b fix/issue-78 /tmp/issue-78 main
tmux new-session -d -s codex-fix78 -c /tmp/issue-78
tmux send-keys -t codex-fix78 'codex --no-alt-screen --full-auto' Enter
```

---

## ⚠️ 安全规则

1. **不要**在 OpenClaw workspace 目录里启动 Codex
2. **不要**在 OpenClaw 的 live 仓库里 checkout 分支
3. 用户明确要求时才用 `danger-full-access` 沙盒模式
4. 修改 config.toml 前**必须**查阅 config_schema.md 确认合法性
5. 模型切换后如果 API 格式不兼容，需要 `/new` 重置会话
6. pane_monitor 的 Telegram chat ID 硬编码在脚本中，更换用户需修改

---

## 前置配置检查清单

首次使用前确认：

- [ ] `~/.codex/config.toml` 中已添加 `notify = ["python3", "<path>/on_complete.py"]`
- [ ] on_complete.py 中的 `TELEGRAM_CHAT_ID` 正确
- [ ] pane_monitor.sh 中的 `CHAT_ID` 正确
- [ ] `codex --version` 可用
- [ ] `openclaw message send` 可发 Telegram
- [ ] `openclaw agent --agent main` 可唤醒 agent
- [ ] tmux 已安装
