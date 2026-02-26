# Codex 提示词模式库

> 最后更新: 2026-02-24

## 提示词设计原则

1. **明确任务边界**：告诉 Codex 做什么、不做什么
2. **提供上下文**：相关文件路径、技术栈、约束条件
3. **利用工具链**：根据任务显式调用 skills、MCP、搜索
4. **分阶段执行**：复杂任务拆分为步骤，逐步确认

## 标准任务模板

### 简单修改

```
在 <文件路径> 中，<具体修改描述>。
修改后运行 <测试命令> 确认没有破坏。
```

### 新功能开发

```
在 <项目路径> 中实现 <功能描述>。

技术要求：
- <具体要求1>
- <具体要求2>

参考文件：
- <相关文件路径>

完成后：
1. 运行测试确认通过
2. 显示 git diff 摘要
```

### Bug 修复

```
Bug 描述：<问题现象>
复现步骤：<步骤>
期望行为：<正确行为>

请分析根因并修复。修复后：
1. 验证 bug 已解决
2. 确认没有引入新问题
3. 简述修复方案
```

### 代码审查

```
/review
```
或非交互式：
```bash
codex review --base origin/main
codex review --uncommitted
```

### 需要搜索的任务

```
$exa 搜索 <关键词> 了解最新的 <技术/方案>，然后基于搜索结果 <执行任务>
```

### 多文件重构

```
重构 <目录> 下的 <描述>。

规则：
- <重构规则>

涉及文件：
- <文件列表或 glob 模式>

使用 /plan 模式先分析影响范围，确认后再执行。
```

## 提示词增强技巧

### 利用 Codex 特有功能

| 场景 | 技巧 |
|------|------|
| 需要精确分析 | 先 `/plan` 分析，确认后再执行 |
| 需要网络信息 | 确保 `web_search = "live"`，prompt 中提示搜索 |
| 处理 Excel/数据 | `$skill_name` 显式调用 |
| 浏览器操作 | 通过 chrome-mcp-server 操作 |
| 深度搜索 | 通过 exa MCP 的 deep_search/deep_researcher |
| 多步骤任务 | 明确步骤编号，每步完成后确认 |

### 上下文管理

| 场景 | 操作 |
|------|------|
| 上下文快满 | `/compact` 压缩历史 |
| 需要引用文件 | `/mention <file>` 附带文件内容 |
| 需要看当前状态 | `/status` 查看 token 用量 |
| 需要看改动 | `/diff` 查看 git diff |

### 模型切换时机

| 从 | 切到 | 时机 |
|----|------|------|
| xhigh | high | 前期分析完成，进入简单实现阶段 |
| xhigh | medium | 重复性修改、格式化 |
| high | xhigh | 遇到难题、架构决策 |

## exec 模式提示词

```bash
# 标准全自动执行
codex exec --full-auto "任务描述"

# 指定模型
codex exec --full-auto -m gpt-5.2 "任务描述"

# 指定工作目录
codex exec --full-auto -C /path/to/project "任务描述"

# 运行时覆盖配置
codex exec --full-auto -c 'model_reasoning_effort="xhigh"' "任务描述"

# 附带图片
codex exec --full-auto -i screenshot.png "根据截图修复 UI"
```
