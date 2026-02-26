# Codex 知识库更新协议

## 更新触发时机

1. **版本变更时**：每次使用前检查 `codex --version`，与 `../state/version.txt` 对比，版本变了立即触发更新
2. **定期更新**：距 `../state/last_updated.txt` 超过 7 天时触发
3. **手动触发**：涛哥要求时

## 数据源（信任度从高到低）

### 来源 1：CLI 本机输出（真相来源，反映实际安装版本）

```bash
codex --version                    # 当前版本
codex features list                # 全部 feature flags + 成熟度 + 状态
codex --help                       # CLI 参数
codex mcp list                     # 已配置的 MCP servers（在交互模式下用 /mcp）
codex exec --help                  # exec 模式参数
codex review --help                # review 模式参数
```

### 来源 2：JSON Schema（结构化真相）

```
https://raw.githubusercontent.com/openai/codex/main/codex-rs/core/config.schema.json
```

config.toml 的完整 JSON Schema，包含所有字段定义、类型、枚举值、描述。

### 来源 3：GitHub 源码（最新实现细节）

```
https://api.github.com/repos/openai/codex/contents/docs          # 文档目录
https://raw.githubusercontent.com/openai/codex/main/docs/<file>   # 具体文档
https://api.github.com/repos/openai/codex/releases?per_page=10   # 版本发布
https://raw.githubusercontent.com/openai/codex/main/codex-rs/tui/src/slash_command.rs  # 斜杠命令源码
```

### 来源 4：官方文档站（结构化，但可能滞后）

```
https://developers.openai.com/codex/overview
https://developers.openai.com/codex/config-reference
https://developers.openai.com/codex/config-basic
https://developers.openai.com/codex/config-advanced
https://developers.openai.com/codex/config-sample
https://developers.openai.com/codex/changelog
https://developers.openai.com/codex/skills
https://developers.openai.com/codex/multi-agent
https://developers.openai.com/codex/guides/agents-md
https://developers.openai.com/codex/noninteractive
https://developers.openai.com/codex/custom-prompts
https://developers.openai.com/codex/security
https://developers.openai.com/codex/cli/slash-commands
```

> ⚠️ 注意：`web_fetch` 对官方文档站被拦截，需要用 `browser` 工具或 `curl` 访问。

### 来源 5：社区（实验性功能线索，需验证）

- GitHub Issues/Discussions: `https://github.com/openai/codex/issues`
- Reddit: `https://www.reddit.com/r/codex/`

## 更新流程

1. 跑 CLI 获取本机实际状态（version + features list + help）
2. 拉取 JSON Schema，与本地 cache 做 diff
3. 抓取 GitHub releases，提取最近变更
4. （可选）浏览官方文档站，补充 CLI/Schema 未覆盖的内容
5. （可选）搜索社区，发现未公开的实验性功能
6. 更新 `features.md`：新增标 [NEW]，废弃标 [DEPRECATED]，社区来源标 [UNVERIFIED]
7. 更新 `config_schema.md`：同步字段变更
8. 更新 `capabilities.md`：检查本机 skills、MCP、模型变化
9. 更新 `changelog.md`：记录本次变更摘要
10. 如有推荐开启的新 feature → 生成 config.toml patch → 报告涛哥确认后应用
11. 更新 `../state/version.txt` 和 `../state/last_updated.txt`

## 校验规则

- 所有写入 features.md 的功能必须能在 `codex features list` 或 JSON Schema 中找到佐证
- 社区来源信息必须标注 [UNVERIFIED]，在 CLI/Schema 中验证后才能去掉标记
- config.toml 修改建议必须通过 JSON Schema 校验类型和枚举值
