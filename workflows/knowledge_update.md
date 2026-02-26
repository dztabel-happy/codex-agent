# 知识库更新工作流

## 概述
定期或触发式更新 Codex 知识库，保持与最新版本同步。

## 触发条件

1. `codex --version` 输出与 `state/version.txt` 不同
2. `state/last_updated.txt` 距今超过 7 天
3. 涛哥手动要求

## 执行步骤

### Step 1: 收集本机数据

```bash
codex --version > /tmp/codex_version.txt
codex features list > /tmp/codex_features.txt
codex --help > /tmp/codex_help.txt
codex exec --help > /tmp/codex_exec_help.txt
cat ~/.codex/config.toml
```

### Step 2: 拉取远程数据

```bash
# 创建缓存目录
mkdir -p /tmp/codex-knowledge-cache

# JSON Schema（最权威的配置参考）
curl -s "https://raw.githubusercontent.com/openai/codex/main/codex-rs/core/config.schema.json" > /tmp/codex-knowledge-cache/config_schema.json

# 源码中的斜杠命令
curl -s "https://raw.githubusercontent.com/openai/codex/main/codex-rs/tui/src/slash_command.rs" > /tmp/codex-knowledge-cache/slash_commands.rs

# GitHub releases
curl -s "https://api.github.com/repos/openai/codex/releases?per_page=10" > /tmp/codex-knowledge-cache/releases.json

# 文档目录
curl -s "https://api.github.com/repos/openai/codex/contents/docs" > /tmp/codex-knowledge-cache/docs_listing.json
```

### Step 3: 浏览官方文档（如可访问）

优先用 browser 工具访问：
- https://developers.openai.com/codex/config-reference
- https://developers.openai.com/codex/skills
- https://developers.openai.com/codex/multi-agent
- https://developers.openai.com/codex/changelog

### Step 4: Diff 分析

对比新旧数据：
- features list 是否有新增/废弃
- schema 字段是否有变化
- 斜杠命令是否有新增
- releases 是否有重要变更

### Step 5: 更新文件

按变更更新：
- `features.md` — 新增标 [NEW]，废弃标 [DEPRECATED]
- `config_schema.md` — 新字段/新类型
- `capabilities.md` — 本机能力变化（skills、MCP、模型）
- `prompting_patterns.md` — 新功能带来的新用法
- `changelog.md` — 追加变更记录

### Step 6: 配置建议

如有新 feature 推荐启用：
1. 生成 config.toml 的具体修改建议
2. 说明变更理由
3. 报告涛哥确认后再应用

### Step 7: 更新状态

```bash
echo "<new_version>" > state/version.txt
echo "<today>" > state/last_updated.txt
```
