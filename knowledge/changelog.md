# Codex 版本变更追踪

## 2026-02-25 — 知识库 v1 完成 + 通知系统验证

### 本次完成

- [x] 知识库 6 文件建成（features/config_schema/capabilities/prompting_patterns/UPDATE_PROTOCOL/changelog）
- [x] SKILL.md 重写为完整工作流引擎（exec + TUI 双模式）
- [x] notify hook（on_complete.py）验证通过：Telegram 双通道（message send + agent wake）
- [x] pane monitor（pane_monitor.sh）审批检测验证通过：Telegram 双通道
- [x] Enter 时序问题解决：文本和 Enter 分两次 send-keys，中间 sleep 1s
- [x] exec 模式 fire-and-forget 验证通过
- [x] TUI + full-auto 模式验证通过
- [x] TUI + 默认审批 + pane monitor 验证通过
- [x] Codex memories 评估：不适用（disable_response_storage + custom provider）

### notify payload 实测字段（比官方文档多）

```json
{
  "type": "agent-turn-complete",
  "thread-id": "uuid",
  "turn-id": "uuid",          // 官方文档未提及
  "cwd": "/path/to/workdir",  // 官方文档未提及
  "last-assistant-message": "...",
  "input-messages": ["..."]
}
```

### 已知模型迁移提示

config.toml 中的 `[notice.model_migrations]`：
- `gpt-5.2` → `gpt-5.3-codex`
- `gpt-5.1-codex-max` → `gpt-5.2-codex`

### 已知配置问题

- `request_rule = true` 在 `[features]` 中，官方文档说 stable/on by default，但 CLI features list 标记 removed，待观察

### 待补充

- [ ] Codex CLI Features 页面详细功能说明 (https://developers.openai.com/codex/cli/features)
- [ ] Advanced Config 页面 (https://developers.openai.com/codex/config-advanced)
- [ ] Rules 系统 (https://developers.openai.com/codex/rules)
- [ ] Non-interactive Mode 详细参数 (https://developers.openai.com/codex/noninteractive)
- [ ] Codex SDK (https://developers.openai.com/codex/sdk)
- [ ] Custom Prompts (https://developers.openai.com/codex/custom-prompts)
- [ ] 本机已安装的 Skills 完整列表（需进入交互模式 `/skills` 查看）
- [ ] notify hook 实际联通测试
- [ ] openclaw CLI 通知命令格式确认
