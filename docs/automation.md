# 自动迭代机制

codex-buddy 每 30 分钟由 Claude Code cron 自动运行一轮 Claude+Codex 协作迭代，持续改进 SKILL.md。

---

## 工作流程

```
CHANGELOG.md 取第一个 [ ] Agenda 项
        ↓
Claude 独立分析（不看 Codex 答案）
        ↓
Codex 独立分析（不传 Claude 答案）
    codex exec -s read-only -o /tmp/output.txt "..."
        ↓
综合两个视角 → 产出 SKILL.md 改动
        ↓
写 discussions/YYYY-MM-DD-<topic>.md
（必须包含 Claude 原文 + Codex 原文 + 综合结论）
        ↓
bash scripts/sync-skill.sh
（同步到 ~/.claude/skills/codex-buddy/SKILL.md）
        ↓
git commit + git push
```

---

## 启动 Cron（Session-only）

在 Claude Code 会话中，cron 会自动运行。退出后消失，需要重建：

```
每次进入新 Claude Code 会话后，告诉 Claude：
"帮我重启 codex-buddy 的 30 分钟迭代 cron"
```

---

## 手动触发一轮迭代

```bash
# 查看当前 Agenda
grep -A 10 "下轮 Agenda" CHANGELOG.md | grep "\[ \]" | head -1

# 手动运行 Codex（取第一个 Agenda 项作为主题）
$(which codex) exec \
  -C . \
  -s read-only \
  --skip-git-repo-check \
  -o /tmp/codex-manual.txt \
  "针对以下主题，给出改进 SKILL.md 的具体方案：<主题>"

cat /tmp/codex-manual.txt
```

---

## sync-skill.sh

```bash
bash scripts/sync-skill.sh
# 将 ./SKILL.md 复制到 ~/.claude/skills/codex-buddy/SKILL.md
# Claude Code 下次调用 codex-buddy skill 时会读取新版本
```

---

## discussions/ 格式规范

每轮讨论文件命名：`YYYY-MM-DD-<topic-slug>.md`

必须包含：
- **问题**：本轮讨论的具体主题
- **Claude 独立视角**：Claude 未看 Codex 答案时的分析原文
- **Codex 独立视角**：Codex 的完整原始输出
- **综合结论**：共识点、分歧点、采纳决策
- **具体改动**：对 SKILL.md 的实际变更说明
