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

Claude + Codex (GPT-4o) 跨模型协作验证。核心价值：两个模型训练路径和 RLHF 偏好不同，系统性盲点不同——让 GPT-4o 独立看一遍，能发现 Claude 流畅合理化掉的问题。

**两模型一致 ≠ 正确。真值来自执行验证，不来自模型共识。**

---

## 前置条件

```bash
npm install -g @openai/codex && codex --version
```

---

## 三种模式

**默认用 Mode B。** 只有 Claude 的结论已成型且只需要定向审查时，才用 Mode A。

### Mode A — Review

Codex 在看到 Claude 结论后做定向审查，不是完全独立判断。

```bash
$(which codex) exec -C <项目目录> -s read-only --skip-git-repo-check \
  -o /tmp/codex-review-$(date +%s).txt \
  "[任务] <用户问题>
[证据] <代码/报错/日志>
[Claude 的结论] <结论/假设>

先基于任务和证据独立判断，再对比 Claude 的结论，列出一致点和分歧点。"
```

**适用：** 已成型结论的 review、找漏项 | **不适用：** 执行决策前、方案探索

### Mode B — Parallel（默认）

不传 Claude 的结论，两模型各自独立回答，完成后比较。

```bash
$(which codex) exec -C <项目目录> -s read-only --skip-git-repo-check \
  -o /tmp/codex-parallel-$(date +%s).txt \
  "[任务] <原始问题>
[约束] <技术栈、限制>
[证据] <相关代码/日志>

给出你的独立结论，标出：最不确定的地方、依赖的关键假设、建议执行哪些验证。"
```

Claude 同步独立作答，完成后综合：标出共识、分歧、采用哪个及原因。

**适用：** 执行决策前、方案探索、架构取舍 | **升 C 的信号：** 有可检验的核心分歧

### Mode C — Debate（两轮封顶）

**C1：** 双方独立陈述，每个论点标注 `[可验证]` / `[文档依据]` / `[经验推断]` / `[逻辑假设]`

```bash
$(which codex) exec -C <项目目录> -s read-only --skip-git-repo-check \
  -o /tmp/codex-c1.txt \
  "就以下问题给出独立立场，每个论点标注类型：[可验证]/[文档依据]/[经验推断]/[逻辑假设]
问题：<问题> | 背景：<最小背景>"
```

**C2：** 只针对对方的 `[可验证]` 或 `[文档依据]` 论点反驳；无新证据则终止。

**适用：** 性能策略、安全边界、复杂并发语义

---

## 传递原则

**传：** 原始任务、约束、可观察事实（代码/报错/日志原文）
**不传：** Claude 的推理过程、定性总结、倾向性措辞（会锚定 Codex 的判断）

证据形式优先级：代码片段 > 代码解释；原始报错 > 错误归因；命令输出 > 结论摘要

---

## 收尾四问

每次运行后必答：

- **Q1 Mode Fit：** 模式选择是否合适？
- **Q2 Key Divergence：** 最大分歧点（结论/假设/证据）？
- **Q3 Verification Gap：** 有本应执行但未执行的外部验证吗？
- **Q4 Learning Signal：** `none` / `confidence_check` / `found_assumption_gap` / `found_fact_risk`

Q2 有实质分歧或 Q3 有验证缺口 → 写 `logs/incidents/YYYY-MM-DD-<topic>.md`

---

## 注意事项

1. 分歧 ≠ Codex 对，是"需要人工判断"的信号
2. 破坏性/不可逆操作前：必须有人工外部验证，不能只靠双模型共识
3. 禁止递归：Codex 结论不再交给 Codex 验证
4. 沙盒：默认 `read-only`；需要执行验证时才升 `-s workspace-write`

完整 CLI 示例见 [`references/cli-examples.md`](./references/cli-examples.md)
