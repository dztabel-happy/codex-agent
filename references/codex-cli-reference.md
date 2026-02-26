# Codex CLI 完整命令参考

## 全局选项

| 选项 | 说明 |
|------|------|
| `-m, --model <MODEL>` | 指定模型 |
| `-c, --config <key=value>` | 覆盖 config.toml 配置（TOML 格式） |
| `-C, --cd <DIR>` | 指定工作目录 |
| `-i, --image <FILE>...` | 附加图片 |
| `-s, --sandbox <MODE>` | 沙盒模式：`read-only` / `workspace-write` / `danger-full-access` |
| `-a, --ask-for-approval <POLICY>` | 审批策略：`untrusted` / `on-request` / `never` |
| `--full-auto` | 等价于 `-a on-request --sandbox workspace-write` |
| `--dangerously-bypass-approvals-and-sandbox` | 无沙盒无审批（极危险） |
| `--search` | 启用实时网络搜索 |
| `--add-dir <DIR>` | 额外可写目录 |
| `--no-alt-screen` | 禁用备用屏幕（tmux 友好，保留滚动历史） |
| `--enable <FEATURE>` | 启用功能标志 |
| `--disable <FEATURE>` | 禁用功能标志 |
| `-p, --profile <PROFILE>` | 使用 config.toml 中的配置档案 |
| `--oss` | 使用本地开源模型（LM Studio / Ollama） |

## 子命令

### `codex` （交互模式）
启动完整 TUI 界面，支持多轮对话。

```bash
codex [OPTIONS] [PROMPT]
```

### `codex exec` （一次性模式）
非交互执行，完成后退出。

```bash
codex exec [OPTIONS] [PROMPT]
```

额外选项：
- `--skip-git-repo-check`：允许在非 git 目录运行
- `--ephemeral`：不持久化 session
- `--json`：以 JSONL 格式输出事件
- `-o, --output-last-message <FILE>`：将最后一条消息写入文件
- `--output-schema <FILE>`：指定输出 JSON Schema

### `codex review` （代码审查）
非交互式代码审查。

```bash
codex review [OPTIONS] [PROMPT]
```

选项：
- `--uncommitted`：审查未提交的更改
- `--base <BRANCH>`：对比指定分支
- `--commit <SHA>`：审查指定 commit

### `codex resume` / `codex fork`
恢复或分叉之前的 session。

```bash
codex resume [--last]
codex fork [--last]
```

### 其他命令
- `codex login` / `codex logout`：认证管理
- `codex mcp`：MCP 服务器管理
- `codex mcp-server`：将 Codex 作为 MCP server 启动
- `codex app`：启动桌面应用
- `codex sandbox`：在 Codex 沙盒中运行命令
- `codex apply`：将最近的 diff 应用到本地
- `codex cloud`：浏览 Codex Cloud 任务
- `codex features`：查看功能标志
- `codex debug`：调试工具

## config.toml 常用配置

配置文件位置：`~/.codex/config.toml`

```toml
# 模型配置
model_provider = "custom"
model = "gpt-5.2"
model_reasoning_effort = "medium"

# 自定义 provider
[model_providers.custom]
name = "custom"
wire_api = "responses"
base_url = "http://127.0.0.1:23000/v1"

# 功能开关
[features]
multi_agent = true
steer = true
shell_snapshot = true
web_search_cached = true

# 项目信任
[projects."/path/to/project"]
trust_level = "trusted"
```

## Reasoning Effort 等级

| 等级 | 说明 | 适用场景 |
|------|------|----------|
| `low` | 最快，最少思考 | 简单修改、格式调整 |
| `medium` | 默认平衡 | 日常编码任务 |
| `high` | 更深入思考 | 复杂逻辑、架构设计 |
| `xhigh` | 最深入 | 困难 bug、复杂算法 |
