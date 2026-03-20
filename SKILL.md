---
name: codex-buddy
description: >
  Use to get an independent Codex (GPT-4o) check before trusting your own answer.
  Trigger on: reviewing code you just wrote, high-stakes architecture choices with
  multiple valid options, facts near your knowledge cutoff, and any destructive or
  irreversible operation. If your answer feels unusually fluent, complete, or confident,
  you should use this skill — fluency is the primary failure signal, not uncertainty.
---

# codex-buddy

Claude + Codex (GPT-4o) 跨模型协作验证。不同训练路径和 RLHF 偏好产生真正不同的视角——通过"受控异质性"打破单模型的闭环自洽。

**两模型一致 ≠ 正确。真值来自外部执行验证，不来自模型共识。**

---

## 前置条件

```bash
npm install -g @openai/codex && codex --version
```

---

## 工作模式（升级链路）

先用 Mode A，发现分歧来自方案空间时升 B，仍有不可解冲突时升 C。

### Mode A — Review（默认）

Codex **先独立重建判断，再与 Claude 对比**，不只是评论 Claude 的文本：

```bash
$(which codex) exec -C <项目目录> -s read-only --skip-git-repo-check \
  -o /tmp/codex-review-$(date +%s).txt \
  "[原始任务] <用户问题>
[可用证据] <代码/报错/日志>
[项目背景] <技术栈、系统边界>
[Claude 待审观点] <Claude 的结论/假设>

先基于任务和证据独立判断，再与 Claude 对比，标出一致点和分歧点。"
```

**适用：** 代码审查、事实验证、破坏性操作前 double-check

### Mode B — Parallel（独立并行）

不传 Claude 答案，各自独立回答后综合：

```bash
$(which codex) exec -C <项目目录> -s read-only --skip-git-repo-check \
  -o /tmp/codex-parallel-$(date +%s).txt \
  "[任务] <用户原始问题>
[硬约束] <技术栈、限制>
[可用证据] <相关片段>
输出：独立结论 / 关键假设 / 缺失验证 / 最不确定的地方"
```

Claude 同步独立作答，完成后综合：标出共识、分歧、采用哪个及原因。

**适用：** 架构取舍、技术选型 | **升 C 的信号：** 有可检验的核心分歧

### Mode C — Debate（两轮封顶）

**C1：** 双方各自独立陈述立场，每个论点标注：`[可执行验证]` / `[文档证据]` / `[经验推断]` / `[逻辑假设]`

```bash
$(which codex) exec -C <项目目录> -s read-only --skip-git-repo-check \
  -o /tmp/codex-c1.txt \
  "就以下问题给出独立立场，每个论点标注类型：[可执行验证]/[文档证据]/[经验推断]/[逻辑假设]
问题：<问题> | 背景：<最小背景>"
```

**C2：** 交换对方 C1 → 只针对 `[可执行验证]` 或 `[文档证据]` 论点反驳。无新证据则直接说"建议终止"。

**终止：** 无新可验证论点 / 分歧不影响结论 / 已达 2 轮

**适用：** 性能策略、安全边界、复杂并发语义

---

## Prompt 独立性协议

| 层级 | 内容 | 规则 |
|------|------|------|
| **传** | 原始问题、目标、约束、可观察事实（代码/报错/日志） | 无限制 |
| **谨慎传** | 最小背景：技术栈、系统边界 | 只传 Codex 无法自己推断的 |
| **降锚后传**（仅 Mode A） | Claude 的结论/假设 | 字段隔离，要求先独立判断再对比 |
| **禁止传** | Claude 的推理过程、定性总结、倾向性措辞 | 会锚定 Codex 结论的任何内容 |

五条硬规则：Context Order（问题>证据>背景>Claude观点）/ Context Budget（Claude观点≤25%）/ Escalation Rule（可验证则必须执行验证）/ Output Contract（区分事实/假设/建议/未验证）/ Abort Rule（证据不足先返回缺失清单）

---

## 收尾四问

每次运行后必答（嵌在对话里即可）：

- **Q1 Mode Fit：** 触发和模式选择是否合适？
- **Q2 Key Divergence：** 最大分歧点（结论/假设/证据）？
- **Q3 Verification Gap：** 有本应执行但未执行的外部验证吗？
- **Q4 Learning Signal：** `none` / `confidence_check` / `found_assumption_gap` / `found_mode_error` / `found_fact_risk`

Q2 有实质分歧、Q3 有验证缺口、Q4 为 `found_*` 时 → 写 `logs/incidents/YYYY-MM-DD-<topic>.md`

---

## 注意事项

1. 独立性协议：字段隔离比措辞重要，Mode B/C 第一轮绝不传 Claude 答案
2. 沙盒：默认 `read-only`；需 Codex 执行验证时用 `-s workspace-write`
3. 分歧 ≠ Codex 对，是"需要人工判断"的信号
4. 禁止递归：Codex 结论不再交给 Codex 验证
5. 真值来源：执行验证 > 文档 > 模型共识

完整 CLI 示例见 [`references/cli-examples.md`](./references/cli-examples.md)
