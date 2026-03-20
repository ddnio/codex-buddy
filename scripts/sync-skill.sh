#!/bin/bash
# 将项目 SKILL.md 同步到实际 Claude Code skill 路径（实现 reload）
SKILL_SRC="/Users/nio/project/github/codex-buddy/SKILL.md"
SKILL_DST="/Users/nio/.claude/skills/codex-buddy/SKILL.md"

cp "$SKILL_SRC" "$SKILL_DST"
echo "[sync-skill] Synced: $SKILL_SRC -> $SKILL_DST"
