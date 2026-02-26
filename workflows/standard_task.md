# 标准任务工作流

## 概述
从接收涛哥的任务到最终交付的完整流程。

## 流程

```
涛哥下发任务
    ↓
[1] 理解任务 → 分析需求、确认范围
    ↓
[2] 评估工具 → 是否需要切换模型/启用 feature/调用 skill
    ↓
[3] 设计提示词 → 结合 capabilities.md + prompting_patterns.md
    ↓
[4] 与涛哥确认 → 展示提示词 + 配置调整计划
    ↓
[5] 执行 → tmux 启动 Codex，发送提示词
    ↓
[6] 等待 → hooks 触发通知（不轮询）
    ↓
[7] 检查输出 → capture-pane + 检查文件
    ↓
[8] 判断质量 → 满足要求？
    ├─ 是 → [9] 向涛哥汇报结果
    └─ 否 → [8a] 向涛哥汇报问题 + 修改计划 → 继续发指令 → 回到 [6]
```

## 详细步骤

### [1] 理解任务

- 确认任务目标、验收标准
- 识别涉及的项目/文件/技术栈
- 不清楚时主动追问，不猜测

### [2] 评估工具

检查 capabilities.md，决定：
- 是否需要 `/model` 切换模型/推理强度
- 是否需要启用/禁用 feature
- 是否需要用 `$skill` 调用特定 skill
- 是否需要 MCP 工具（exa 搜索、chrome 浏览器等）
- 是否需要先 `/plan` 分析再执行

### [3] 设计提示词

参考 prompting_patterns.md，构建提示词：
- 明确任务描述
- 提供必要上下文（文件路径、技术约束）
- 指定工具调用（如需）
- 指定完成条件

### [4] 与涛哥确认

向涛哥展示：
- 最终提示词内容
- 任何配置调整（模型切换、feature 开关等）
- 预估复杂度

等涛哥确认后再执行。

### [5] 执行

```bash
# 创建 tmux session
tmux new-session -d -s codex-<任务名> -c <工作目录>

# 启动 Codex（如需特殊配置）
tmux send-keys -t codex-<任务名> 'codex --no-alt-screen' Enter

# 等待启动完成（信任确认等）
sleep 3
tmux capture-pane -t codex-<任务名> -p -S -20

# 如需切换模型
tmux send-keys -t codex-<任务名> '/model gpt-5.2 xhigh' Enter

# 发送提示词
tmux send-keys -t codex-<任务名> '<提示词>' Enter
```

### [6] 等待

- hooks 配置 `notify` 会在 Codex 完成 turn 时触发通知
- 不需要轮询，等待被唤醒
- 如 hooks 未触发（超时），可手动 capture-pane 检查

### [7] 检查输出

```bash
# 查看 Codex 的回复
tmux capture-pane -t codex-<任务名> -p -S -200

# 检查产出文件
ls -la <工作目录>/<预期输出>
cat <关键文件>
```

### [8] 判断质量

评估标准：
- 是否完成了任务目标
- 代码质量是否合格
- 是否引入了新问题
- 测试是否通过

### [8a] 迭代修改

向涛哥汇报：
1. Codex 的回复摘要
2. 发现的问题
3. 准备给 Codex 的修改指令
4. 修改原因

然后继续发送指令给 Codex。

### [9] 最终汇报

向涛哥汇报：
1. 任务完成状态
2. 关键变更摘要
3. 需要注意的事项
