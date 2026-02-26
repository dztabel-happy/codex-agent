# Codex 本机能力清单

> 最后更新: 2026-02-25

## 基本信息

- **版本**: 0.104.0
- **默认模型**: gpt-5.2
- **默认推理强度**: xhigh
- **Provider**: custom (http://127.0.0.1:23000/v1, Responses API)
- **个性**: friendly
- **网页搜索**: live（实时）
- **沙盒**: 未显式设置（交互模式默认按审批策略）

## 已安装 MCP Servers

| 名称 | 类型 | 说明 |
|------|------|------|
| `ace-tool` | stdio (npx) | ACE MCP 工具 |
| `exa` | stdio (npx) | Exa 搜索引擎（web_search, deep_search, code_context, company_research, crawling, linkedin, deep_researcher） |
| `chrome-mcp-server` | stdio (node) | Chrome 浏览器控制 |

## 已安装 Skills

> 通过 `/skills` 或 `$` 前缀在交互模式查看/调用。
> 调用方式：在 prompt 中使用 `$skill_name 任务描述`

### Skill 系统详解

**目录扫描位置**（优先级从高到低）：

| 作用域 | 路径 | 说明 |
|--------|------|------|
| REPO | `$CWD/.agents/skills/` | 当前目录 |
| REPO | 上级到 repo root 的 `.agents/skills/` | 仓库共享 |
| USER | `$HOME/.agents/skills/` | 用户级 |
| ADMIN | `/etc/codex/skills/` | 系统级 |
| SYSTEM | Codex 内置 | OpenAI 官方 |

**渐进式加载**：Codex 启动时只读 name + description，使用时才加载完整 SKILL.md。

**Skill 结构**：
```
my-skill/
├── SKILL.md           # 必需：指令 + 元数据
├── scripts/           # 可选：可执行脚本
├── references/        # 可选：参考文档
├── assets/            # 可选：模板资源
└── agents/
    └── openai.yaml    # 可选：UI元数据 + 依赖声明
```

**调用方式**：
- 显式：`$skill-name 任务描述` 或 `/skills` 选择
- 隐式：Codex 根据 description 自动匹配

**管理**：
- 安装：`$skill-installer install the xxx skill`
- 创建：`$skill-creator`
- 禁用（不删除）：在 config.toml 中：
  ```toml
  [[skills.config]]
  path = "/path/to/skill/SKILL.md"
  enabled = false
  ```

**openai.yaml 元数据**：
```yaml
interface:
  display_name: "显示名"
  icon_small: "./assets/icon.svg"
  brand_color: "#3B82F6"
  default_prompt: "默认提示词"
policy:
  allow_implicit_invocation: false  # 禁止隐式调用
dependencies:
  tools:
    - type: "mcp"
      value: "server-name"
      transport: "streamable_http"
      url: "https://..."
```

## 已开启的 Feature Flags

```
undo, shell_tool, unified_exec, shell_snapshot, js_repl, child_agents_md,
apply_patch_freeform, enable_request_compression, multi_agent,
skill_mcp_dependency_install, steer, collaboration_modes, personality,
request_rule(⚠️ removed，应清理)
```

## Codex 自带记忆系统（memories）

**状态**：❌ 不建议开启

原因：
1. `disable_response_storage = true` 禁用了服务端存储，memories 无法持久化
2. Custom provider 代理不保证 Responses API 的 thread 持久化兼容性
3. 切换上游供应商后 phase_1/phase_2 模型可能不可用
4. 我们已有 OpenClaw 三层记忆系统，功能更强且不依赖供应商

如需要：`[features] memories = true` + `[memories]` 配置 phase_1_model/phase_2_model

> 通过 custom provider 代理，具体可用模型取决于代理配置。

| 模型 | 推荐场景 | 切换方式 |
|------|---------|---------|
| gpt-5.2 (默认) | 大多数任务 | 已是默认 |
| gpt-5.2 xhigh | 复杂推理、关键决策 | `/model gpt-5.2 xhigh`（已是默认） |
| gpt-5.2 high | 平衡质量与速度 | `/model gpt-5.2 high` |
| gpt-5.2 medium | 简单任务、节省 token | `/model gpt-5.2 medium` |

> ⚠️ 注意 config.toml 中有模型迁移提示：
> - `gpt-5.2` → `gpt-5.3-codex`
> - `gpt-5.1-codex-max` → `gpt-5.2-codex`

## 模型选择策略

| 任务类型 | 推荐配置 |
|---------|---------|
| 简单修改/格式化 | gpt-5.2 medium |
| 常规开发 | gpt-5.2 high |
| 复杂架构/超难 bug | gpt-5.2 xhigh（当前默认） |
| 代码审查 | 可用 `review_model` 单独配置 |

## 已信任的项目目录

```
/Users/abel
/Users/abel/project/claude-code-hub
/Users/abel/project/cold-sim-opt
/Users/abel/project/work_notebook_ob
/Users/abel/project/test2
/Users/abel/project
/Users/abel/.cache/opencode/node_modules/oh-my-opencode-slim/dist
```

## 提示词增强策略

### Skill 调用
```
$skill_name 任务描述
```
例：`$xlsx 读取 data.xlsx 并提取第三列`

### 模型切换（交互模式）
```
/model gpt-5.2 xhigh
```

### MCP 工具调用
Codex 会根据 prompt 自动调用已配置的 MCP 工具，也可显式提示：
```
使用 exa 搜索 "XXX" 的最新信息
```

### 多智能体详解

**启用**：`[features] multi_agent = true`（已开启）

**工作方式**：
- Codex 自动决定何时 spawn 子 agent，也可手动要求
- 子 agent 并行运行，Codex 等待所有结果后统一返回
- 子 agent 继承当前沙盒策略，但使用非交互审批

**管理命令**：
- `/agent` — 查看/切换活跃线程
- 可直接要求 Codex steer/stop/close 子 agent

**内置角色**：
- `default` — 通用
- `worker` — 工作线程
- `explorer` — 代码探索

**自定义角色**：
```toml
[agents]
max_depth = 3       # 最大嵌套
max_threads = 5     # 最大并发

[agents.reviewer]
description = "代码审查，关注安全和正确性"
config_file = "agents/reviewer.toml"
```

角色配置文件可覆盖：`model`、`model_reasoning_effort`、`sandbox_mode`、`developer_instructions` 等。

**示例用法**：
```
对当前 PR 进行审查，每个维度 spawn 一个 agent：
1. 安全问题
2. 代码质量
3. Bug
4. 竞态条件
5. 测试稳定性
```

### 协作模式
```
/plan     # 切换到 Plan 模式（只分析不执行）
/collab   # 切换协作模式
```
