---
name: codex-buddy
description: >
  Cross-model validation via Codex CLI (GPT-4o). Invoke this skill when:
  (1) reviewing Claude's own code or analysis to catch self-validation blindspots,
  (2) making high-stakes architecture decisions where multiple valid approaches exist,
  (3) Claude's answer feels suspiciously smooth or too confident (fluency is a red flag),
  (4) asserting facts near Claude's knowledge cutoff,
  (5) user explicitly asks for cross-model collaboration or a second opinion.
  Do NOT invoke for simple Q&A, obvious tasks, pure formatting, or anything already iterated with Codex.
  IMPORTANT: The more confident Claude feels, the more this skill should trigger — overconfidence is the exact failure mode it protects against.
---

# codex-buddy

Claude + Codex (GPT-4o) 跨模型协作验证。核心价值：两个模型的训练路径、RLHF 偏好、执行能力不同，通过引入"受控异质性"打破单模型的闭环自洽。

**注意：两模型一致 ≠ 正确。共识只代表共享训练分布，真值来自外部执行验证。**

---

## 前置条件

```bash
npm install -g @openai/codex
codex --version
# 使用 $(which codex) 获取二进制路径
```

---

## 触发判断（风险分级）

**触发**（满足任意一项）：
- 破坏性操作或涉及环境状态变更
- 存在两个以上同样合理的方案（架构、技术选型）
- 事实可能过时或接近知识截止点
- 无法通过本地执行快速验证
- Claude 置信度很高但推理链短（越流畅越危险）
- 用户明确要求跨模型验证

**不触发**（节省成本）：
- 简单问答、明确标准答案
- 纯格式/文档操作
- 已在 Codex 会话迭代过的内容

---

## 工作模式（升级链路）

三种模式是**升级路径**，不是平行选择：先用 Mode A，发现分歧来自方案空间时升 B，仍有不可解冲突时升 C。

### Mode A — Review（默认）

Claude 产出后，让 Codex 审查**结论 + 关键假设 + 未验证部分**（不只是最终结果）：

```bash
CODEX_BIN=$(which codex)
OUTPUT_FILE="/tmp/codex-review-$(date +%s).txt"

$CODEX_BIN exec \
  -C <项目目录> \
  -s read-only \
  --skip-git-repo-check \
  -o "$OUTPUT_FILE" \
  "请审查以下 Claude 的产出，重点检查：
1. 结论是否有明显错误
2. 哪些关键假设没有被验证
3. 忽略了哪些边界条件或风险
4. 与你的独立判断有哪些分歧

Claude 的产出：
<粘贴内容>"

cat "$OUTPUT_FILE"
```

读取输出，向用户报告分歧点。**分歧 = "需要人工判断"的信号，不代表 Codex 一定对。**

**适用：** 代码审查、事实验证、高风险操作前 double-check

---

### Mode B — Parallel（独立并行）

不传 Claude 的答案，保持独立性，各自回答同一问题后综合：

```bash
CODEX_BIN=$(which codex)
OUTPUT_FILE="/tmp/codex-parallel-$(date +%s).txt"

$CODEX_BIN exec \
  -C <项目目录> \
  -s read-only \
  --skip-git-repo-check \
  -o "$OUTPUT_FILE" \
  "请独立回答：<原始问题>
（不需要与任何其他模型保持一致，给出你自己的独立判断）"

cat "$OUTPUT_FILE"
```

Claude 同步独立作答，然后综合两个视角：标出共识、标出分歧、说明采用哪个及原因。

**适用：** 架构取舍、API 设计、技术选型

**升级到 Mode C 的信号：** Mode B 后仍有核心分歧，且分歧有可检验依据。

---

### Mode C — Debate（多轮，硬性 3 轮封顶）

**仅在 Mode B 发现实质性分歧后使用。**

**第 1 轮：** Claude 先表态 → Codex 独立反驳

```bash
$CODEX_BIN exec \
  -C <项目目录> \
  -s read-only \
  --skip-git-repo-check \
  -o /tmp/codex-debate-r1.txt \
  "当前讨论的问题是：<问题描述>

Claude 的立场是：<Claude 的观点>

请从不同角度反驳或补充。注意：每个论点请标注其类型
- [可执行验证] 可通过运行代码/命令证实
- [文档证据] 有明确文档/规范支持
- [经验推断] 基于工程经验的合理推断
- [逻辑假设] 纯逻辑推演，未经验证"
```

**第 2 轮：** Claude 回应 Codex 的反驳，聚焦有新证据的分歧点

**终止规则（满足任意一项即终止，不强制跑满 3 轮）：**
- 分歧已缩小到不影响结论
- 某一轮没有出现标记为 `[可执行验证]` 或 `[文档证据]` 的新论点（纯修辞循环）
- 已达 3 轮（硬性上限）

**最终裁决：** 优先采信有外部执行验证的论点；无法验证的分歧，明确告知用户需要人工判断。

**适用：** 性能优化策略、安全边界、复杂并发语义

---

## 注意事项

1. **独立性保护**：Mode B 和 Mode C 第一轮不要把 Claude 答案传给 Codex，避免锚定效应
2. **沙盒选择**：默认 `read-only`；需要 Codex 执行命令验证时用 `-s workspace-write`，告知用户
3. **分歧解读**：Codex 给出分歧 ≠ Codex 对，是"需要人工关注"的信号
4. **禁止递归**：Codex 的结论不再交给 Codex 验证
5. **真值来源**：运行代码 > 查文档 > 模型共识

---

## 完整 CLI 参考

见 `references/cli-examples.md`（含实际可运行示例）。
