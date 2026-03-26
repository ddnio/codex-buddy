# CLAUDE.md

> AI 代理入口。必须先读完本文件再开始任何操作。
> 完整迭代手册见 `references/WORKFLOW.md`。

---

## 仓库目标

维护并改进 `codex-buddy`——让 Claude 与 Codex (GPT-4o) 协作进行跨模型验证的 Claude Code skill。

**唯一产物是 `SKILL.md`**，其他所有文件服务于它的质量。

每次迭代前必问：**这个改动让两个模型的对话更有效，还是只是加规范层？** 只有前者才做。

---

## 启动顺序（必须遵守，不能跳过）

```
1. 读 STATUS.md → 确认 health_status 和 next_safe_step
2. 运行 bash scripts/verify-repo.sh → 读取全部输出
3. verify 失败 → 进入 triage 模式（修复 confirmed_failures），不继续迭代
4. verify 通过 → 运行 WORKFLOW.md Step 1 自主选题（STATUS.md selected_item 若已填则直接用）
```

**verify 失败 = triage 模式，不是终止迭代。**

---

## 单一真相源

| 内容 | 来源 |
|------|------|
| skill 当前内容 | `SKILL.md` |
| 项目状态 / 失败记录 | `STATUS.md` |
| 历史迭代记录 | `CHANGELOG.md`（只读历史，不作调度源） |
| 完整迭代流程 | `references/WORKFLOW.md` |
| CLI 示例 | `references/cli-examples.md` |

冲突时优先级：`SKILL.md` > `STATUS.md` > `CLAUDE.md` > 其他

---

## 硬性约束（不可违反）

- `SKILL.md` 体积 < 150 行
- description 是唯一触发入口，body 不重复触发条件
- 对话协议（Probe / Follow-up / Challenge）和升级流程不可破坏
- 传递原则：不传 Claude 的推理过程和倾向性措辞
- 修改 SKILL.md 后必须执行 `bash scripts/sync-skill.sh` 并做 reload 验证
- `discussions/` 里的原始输出不可裁剪或删改

---

## Reload 验证（改 SKILL.md 后必做）

```bash
bash scripts/sync-skill.sh
diff "$(pwd)/SKILL.md" ~/.claude/skills/codex-buddy/SKILL.md && echo "✓ in sync" || echo "✗ DRIFT"
head -9 ~/.claude/skills/codex-buddy/SKILL.md
```

---

## No-op 轮次

如果本轮 Codex 调用没有新发现，**显式**记录：`本轮 no-op，理由：[具体理由]`。不需要编造增量发现。

---

## 文件职责速查

| 文件/目录 | 职责 |
|-----------|------|
| `SKILL.md` | skill 主体，唯一对外发布的文件 |
| `STATUS.md` | 当前仓库状态快照（调度源） |
| `CHANGELOG.md` | 历史版本记录（只读参考） |
| `discussions/` | 每轮 Claude+Codex 完整讨论记录，不可删改 |
| `evals/evals.json` | 触发判断测试用例 |
| `references/WORKFLOW.md` | 完整迭代手册（工具、流程、格式规范） |
| `references/cli-examples.md` | 完整 CLI 用法示例 |
| `scripts/sync-skill.sh` | 同步 SKILL.md 到本地 skill 安装路径 |
| `scripts/verify-repo.sh` | 仓库健康检查（每轮启动前运行） |
| `logs/incidents/` | 高价值失败案例复盘（可选，按需创建） |
