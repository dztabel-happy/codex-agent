#!/bin/bash
# codex-agent 三位置同步脚本
# 用法: ./sync.sh [commit message]
#
# 同步 codex-agent skill 到三个位置：
#   1. /Users/abel/project/codex-agent          (独立 GitHub 仓库，公开)
#   2. /Users/abel/project/oh-my-openclaw/skills/codex-agent  (oh-my-openclaw 仓库)
#   3. ~/.openclaw/workspace/skills/codex-agent  (OpenClaw 实际运行的 skill)
#
# 以 codex-agent 独立仓库为 source of truth，同步到其他两个位置。

set -euo pipefail

SOURCE="/Users/abel/project/codex-agent"
OH_MY="/Users/abel/project/oh-my-openclaw/skills/codex-agent"
WORKSPACE="$HOME/.openclaw/workspace/skills/codex-agent"
MSG="${1:-sync codex-agent updates}"

echo "📦 Source: $SOURCE"
echo ""

# 同步文件（排除 .git 和 __pycache__）
echo "1️⃣  Syncing to oh-my-openclaw..."
rsync -av --delete \
    --exclude '.git' \
    --exclude '__pycache__' \
    --exclude '.gitignore' \
    "$SOURCE/" "$OH_MY/"
echo ""

echo "2️⃣  Syncing to workspace..."
rsync -av --delete \
    --exclude '.git' \
    --exclude '__pycache__' \
    --exclude '.gitignore' \
    "$SOURCE/" "$WORKSPACE/"
echo ""

# 提交 codex-agent
echo "3️⃣  Committing codex-agent..."
cd "$SOURCE"
if git diff --quiet && git diff --cached --quiet; then
    echo "   No changes in codex-agent"
else
    git add -A
    git commit -m "$MSG"
    git push
    echo "   ✅ Pushed to codex-agent"
fi
echo ""

# 提交 oh-my-openclaw
echo "4️⃣  Committing oh-my-openclaw..."
cd /Users/abel/project/oh-my-openclaw
if git diff --quiet && git diff --cached --quiet; then
    echo "   No changes in oh-my-openclaw"
else
    git add -A
    git commit -m "codex-agent: $MSG"
    git push
    echo "   ✅ Pushed to oh-my-openclaw"
fi
echo ""

# 提交 workspace
echo "5️⃣  Committing workspace..."
cd "$HOME/.openclaw/workspace"
if git diff --quiet skills/codex-agent/ && git diff --cached --quiet skills/codex-agent/; then
    echo "   No changes in workspace"
else
    git add skills/codex-agent/
    git commit -m "codex-agent: $MSG"
    echo "   ✅ Committed workspace"
fi

echo ""
echo "🎉 Done! All three locations synced."
