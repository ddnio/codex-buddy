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

## Prompt 独立性协议

> 调用 Codex 的真正价值来自独立性。独立性一旦被污染，双模型验证退化为单模型回声放大。

### 四层传递规则

| 层级 | 内容 | 规则 |
|------|------|------|
| **传** | 用户原始问题、目标、硬约束、可观察事实（报错/日志/代码/接口定义） | 无限制 |
| **谨慎传** | 最小必要背景：技术栈、系统边界、相关模块 | 只传 Codex 无法自己推断的部分 |
| **降锚后可传**（仅 Mode A） | Claude 的结论/假设/未验证点 | 必须字段隔离，必须要求 Codex 先独立判断再对比 |
| **禁止传** | Claude 的推理过程、定性总结、倾向性措辞、预设角色 | 任何会锚定 Codex 结论/立场/优先级的内容 |

**一句话原则：传证据，不传结论；传约束，不传倾向；传问题，不传答案。**

### 五条硬性规则

1. **Context Order**：原始问题 > 客观证据 > 最小背景 > Claude 观点（如需传）
2. **Context Budget**：Claude 观点不能超过总上下文的 25%
3. **Escalation Rule**：若分歧可通过命令/测试验证，必须升到执行验证，不能停留在模型争论
4. **Output Contract**：要求 Codex 输出必须区分：事实 / 假设 / 建议 / 未验证
5. **Abort Rule**：若可用证据不足，Codex 应先返回"证据不足，需补充 X"，不给结论

---

## 工作模式（升级链路）

三种模式是**升级路径**：先用 Mode A，发现分歧来自方案空间时升 B，仍有不可解冲突时升 C。

### Mode A — Review（默认）

Claude 产出后，Codex **先独立重建判断，再与 Claude 对比**（不只是评论 Claude 的文本）：

```bash
CODEX_BIN=$(which codex)
OUTPUT_FILE="/tmp/codex-review-$(date +%s).txt"

$CODEX_BIN exec \
  -C <项目目录> \
  -s read-only \
  --skip-git-repo-check \
  -o "$OUTPUT_FILE" \
  "你将独立审查一个工程问题，然后与另一个模型的观点对比。

[原始任务]
<用户的原始问题>

[可用证据]
<代码/报错/日志/接口定义 — 只粘贴与判断直接相关的片段>

[项目背景（最小必要）]
<技术栈、系统边界>

[Claude 待审观点]
<Claude 的结论/假设/未验证点>

请按此顺序输出：
1. 基于任务和证据，你的独立判断是什么（先不看 Claude 观点）
2. 你的判断依赖哪些关键假设
3. 哪些仍未验证，建议如何验证
4. 与 Claude 的一致点和分歧点（此时再对比）
5. 你最不确定的地方

注意：不要因为 Claude 已有结论而默认其前提成立。"

cat "$OUTPUT_FILE"
```

**适用：** 代码审查、事实验证、高风险操作前 double-check

---

### Mode B — Parallel（独立并行）

不传 Claude 的答案，各自独立回答，要求结构化输出方便对比：

```bash
CODEX_BIN=$(which codex)
OUTPUT_FILE="/tmp/codex-parallel-$(date +%s).txt"

$CODEX_BIN exec \
  -C <项目目录> \
  -s read-only \
  --skip-git-repo-check \
  -o "$OUTPUT_FILE" \
  "你将独立分析一个工程问题。不要假设其他模型的结论是对的；如果材料不足，先指出缺失信息。

[任务]
<用户原始问题>

[硬约束]
<技术栈、限制条件>

[可用证据]
<与判断直接相关的代码/配置/文档片段>

[你需要输出]
1. 你的独立结论
2. 结论依赖的关键假设
3. 仍缺失的验证（如果有）
4. 可执行验证建议
5. 你最不确定的地方"

cat "$OUTPUT_FILE"
```

Claude 同步独立作答（不看 Codex 输出），然后综合两个视角：标出共识、标出分歧、说明采用哪个及原因。

**适用：** 架构取舍、API 设计、技术选型

**升级到 Mode C 的信号：** Mode B 后仍有核心分歧，且分歧有可检验依据。

---

### Mode C — Debate（两轮，硬性封顶）

**仅在 Mode B 发现实质性分歧后使用。**

**C1：双方各自独立陈述**（不交换意见，各自写立场 + 证据类型）

Claude 先写：
- 立场
- 每个论点的类型：`[可执行验证]` / `[文档证据]` / `[经验推断]` / `[逻辑假设]`

Codex 同步独立写（不传 Claude 立场）：

```bash
$CODEX_BIN exec -C <项目目录> -s read-only --skip-git-repo-check \
  -o /tmp/codex-c1.txt \
  "请就以下问题给出你的独立立场。每个论点请标注类型：
  [可执行验证] / [文档证据] / [经验推断] / [逻辑假设]

  问题：<问题描述>
  背景：<最小背景>"
```

**C2：交换反驳**（将对方的 C1 输出传给彼此）

```bash
$CODEX_BIN exec resume --last \
  -o /tmp/codex-c2.txt \
  "以下是另一方的立场：<Claude C1 输出>
  请针对其中有 [可执行验证] 或 [文档证据] 标注的论点进行反驳或确认。
  没有新的可验证证据时，直接说'此轮无新证据，建议终止'。"
```

**终止规则（满足任意一项）：**
- 某轮没有出现新的 `[可执行验证]` 或 `[文档证据]` 论点 → 立即终止
- 分歧已不影响结论
- 已达 2 轮（硬性上限）

**最终裁决：** 优先采信有外部执行验证的论点；无法验证的分歧，明确告知用户需要人工判断。

**适用：** 性能优化策略、安全边界、复杂并发语义

---

## 注意事项

1. **独立性协议优先**：见上方"Prompt 独立性协议"，字段隔离比措辞更重要
2. **沙盒选择**：默认 `read-only`；需要 Codex 执行命令验证时用 `-s workspace-write`，告知用户
3. **分歧解读**：Codex 给出分歧 ≠ Codex 对，是"需要人工关注"的信号
4. **禁止递归**：Codex 的结论不再交给 Codex 验证
5. **真值来源**：运行代码 > 查文档 > 模型共识

---

## 完整 CLI 参考

见 `references/cli-examples.md`（含实际可运行示例）。
