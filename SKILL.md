---
name: codex-buddy
description: >
  Use when a task needs independent second-model verification rather than a single-model answer.
  Trigger when reviewing or approving code/logic, evaluating a design or architecture decision,
  checking correctness or safety, confirming current or version-specific facts, before any
  destructive or irreversible action, or when asked to assess this skill itself or explain why
  it did or did not trigger. If being wrong would be costly, use this skill.
---

# codex-buddy

核心目标：**让两边在尽量少相互污染的前提下，并行产生可比较的判断。** 不是"让 Codex review Claude"，而是打破单模型的闭环自洽。

**两模型一致 ≠ 正确。真值来自执行验证，不来自模型共识。**

---

## 快速开始

```bash
$(which codex) exec -C <项目目录> -s read-only --skip-git-repo-check \
  -o /tmp/codex-b.txt \
  "[任务] <原始问题>
[约束] <技术栈、限制>
[证据] <代码/日志原文>

给出独立结论，标出：最不确定的地方、关键假设、建议验证什么。"
```

读取输出，与 Claude 的独立结论比较。有实质发现时回答收尾问题（见下方）。

---

## 三种模式（按信息污染程度）

**选模式的本质：你要传给 Codex 多少 Claude 的先验信息？**

| 模式 | 传递了什么 | 何时用 |
|---|---|---|
| **Mode B（默认）** | 不传 Claude 结论，真正独立 | 做决定前、方案探索、任何不确定的场景 |
| Mode A（受限） | 传了 Claude 结论，定向审查 | 结论已成型，只需找漏项 |
| Mode C（按需） | 两边交换，短辩论 | 有核心分歧且可被证据裁决 |

### Mode B — Parallel（默认）

```bash
$(which codex) exec -C <项目目录> -s read-only --skip-git-repo-check \
  -o /tmp/codex-b-$(date +%s).txt \
  "[任务] <原始问题>
[约束] <技术栈、限制>
[证据] <相关代码/日志原文>

给出独立结论，标出：最不确定的地方、关键假设、建议验证什么。"
```

Claude 同步独立作答，完成后综合：标出共识、分歧、采用哪个及原因。

### Mode A — Review（受限，已锚定）

```bash
$(which codex) exec -C <项目目录> -s read-only --skip-git-repo-check \
  -o /tmp/codex-a-$(date +%s).txt \
  "[任务] <用户问题>
[证据] <代码/报错/日志>
[Claude 的结论] <结论/假设>

先基于任务和证据独立判断，再对比 Claude 的结论，列出一致点和分歧点。"
```

### Mode C — Debate（两轮封顶）

**C1：** 双方独立陈述，每个论点标注 `[可验证]` / `[文档依据]` / `[经验推断]` / `[逻辑假设]`

```bash
$(which codex) exec -C <项目目录> -s read-only --skip-git-repo-check \
  -o /tmp/codex-c1.txt \
  "就以下问题给出独立立场，每个论点标注类型：[可验证]/[文档依据]/[经验推断]/[逻辑假设]
问题：<问题> | 背景：<最小背景>"
```

**C2：** 只针对对方的 `[可验证]` 或 `[文档依据]` 论点反驳；无新证据则终止。

---

## 传递原则

**不传：** Claude 的推理过程、定性总结、倾向性措辞（锚定 Codex 的判断）

**传原始证据，不传加工过的叙事：**
代码片段 > 代码解释 ｜ 原始报错 > 错误归因 ｜ 命令输出 > 结论摘要

---

## 漏触发红旗（这些念头意味着你在合理化跳过）

| 念头 | 现实 |
|------|------|
| "这只是个讨论/聊天" | 讨论性判断同样有闭环自洽风险 |
| "我在解释为什么没触发" | 自我解释正是最需要第二意见的时候 |
| "这个答案很清晰不需要验证" | 清晰感 = fluency = 触发信号 |
| "这是关于 skill 自身的评估" | 自我评估是最容易自我服务的场景 |

---

## 升级 / 停止规则

- 有决策但无验证路径 → 停在 B，不升 C
- 有核心分歧且能靠实验/文档裁决 → 升 C 或直接验证
- 涉及不可逆操作 → 不以模型共识收尾，必须外部验证

---

## 收尾（有实质内容时才写）

只在以下情况写：
- **判断改变**：Codex 让你改变了什么？（没有变化不需要写）
- **验证缺口**：有本应执行但未执行的外部验证？
- **污染风险高**：Prompt 传了 Claude 的推理/结论？

三项均无 → 直接给出综合结论，跳过收尾。
任一有内容 → 简要写出，并判断是否需要写 `logs/incidents/YYYY-MM-DD-<topic>.md`。

---

## 注意事项

1. 分歧 ≠ Codex 对，是"需要人工判断"的信号
2. 禁止递归：Codex 结论不再交给 Codex 验证
3. 沙盒：默认 `read-only`；需要执行验证时才升 `-s workspace-write`
4. 破坏性/不可逆操作前：必须人工外部验证，不能只靠双模型共识

完整 CLI 示例见 [`references/cli-examples.md`](./references/cli-examples.md)
