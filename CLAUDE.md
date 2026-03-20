# CLAUDE.md — 仓库工作协议

> 如果你是 Claude Code 代理，在此仓库工作前请读完本文件。

---

## 仓库目标

维护并持续改进 `codex-buddy` ——一个让 Claude 与 Codex (GPT-4o) 协作进行跨模型验证的 Claude Code skill。

**真正的产物只有一个：`SKILL.md`**，其他所有文件都服务于它的质量。

---

## 文件职责

| 文件 | 职责 | 修改频率 |
|------|------|---------|
| `SKILL.md` | skill 主体，**每次改动必须同步到 `~/.claude/skills/codex-buddy/SKILL.md`** | 每轮迭代 |
| `CHANGELOG.md` | 版本记录 + 下轮 Agenda | 每次改 SKILL.md |
| `discussions/` | 每轮 Claude+Codex 完整讨论原文，不可删改 | 每轮迭代 |
| `evals/evals.json` | 触发判断测试用例 | 新增触发场景时 |
| `references/cli-examples.md` | 实际可运行的 CLI 示例 | CLI 接口变化时 |
| `scripts/sync-skill.sh` | 同步 SKILL.md 到实际 skill 路径 | 路径变更时 |
| `docs/automation.md` | 自动迭代机制说明 | 流程变更时 |

---

## 修改 SKILL.md 的规则

**每次改动后必须执行：**

```bash
bash scripts/sync-skill.sh
```

**不能破坏的稳定接口：**
- 三种模式的名称（Mode A / B / C）及升级链路关系
- Prompt 独立性协议的五条硬性规则
- 触发判断的风险分级逻辑

**每次修改必须同步：**
- `CHANGELOG.md`：追加版本记录，更新 Agenda `[x]` 状态
- 如果改动来自 Claude+Codex 讨论，在 `discussions/` 写完整讨论记录

---

## 自动迭代工作流

每 30 分钟由 Claude Code cron 触发一轮迭代（session-only，重启后需重建）：

1. 从 `CHANGELOG.md` 取第一个 `[ ]` Agenda 项
2. Claude 独立分析该主题
3. Codex 独立分析（不传 Claude 答案，保持独立性）
4. 综合两个视角 → 改 SKILL.md
5. 写 `discussions/YYYY-MM-DD-<topic>.md`（必须包含双方原文）
6. `sync-skill.sh` → `git commit` → `git push`

详细说明见 [`docs/automation.md`](./docs/automation.md)。

---

## 验证要求

改完 SKILL.md 后，至少检查：
- [ ] 五条独立性协议规则未被破坏
- [ ] Mode A/B/C 的升级链路逻辑仍然一致
- [ ] sync-skill.sh 已执行（`~/.claude/skills/codex-buddy/SKILL.md` 已更新）
- [ ] CHANGELOG.md 已更新

---

## 安全边界

- 不要把本地绝对路径写进 `SKILL.md`（用 `$(which codex)` 代替硬编码路径）
- 不要把私有环境信息、token、用户名写进任何提交
- `discussions/` 里的 Codex 原始输出不可篡改
