---
name: codex-buddy
description: >
  Use when starting any conversation — loads the verification policy for this session.
  Loading this skill does not automatically trigger codex exec; it establishes when and how to use it.
---

# codex-buddy

核心目标：**让两边在尽量少相互污染的前提下，并行产生可比较的判断。** 不是"让 Codex review Claude"，而是打破单模型的闭环自洽。

**两模型一致 ≠ 正确。真值来自执行验证，不来自模型共识。**

<EXTREMELY-IMPORTANT>
加载此 skill ≠ 执行 codex exec。加载建立会话级验证政策；执行按 VEM 级别条件触发。

每个回合，回答之前先分类（不得跳过，"只是讨论"不是豁免条件）：
1. 当前任务是 V0 / V1 / V2 / V3 中的哪一级？
2. 该级别要求执行 codex exec 吗？

按级别条件执行：V0 不调用 Codex | V1 可选核对（跳过标 `[未验证]`）| V2 提出方先验证 | V3 必须人工/外部验证

若出现"这只是讨论""答案很清晰"等念头 → 这是跳过分类步骤的信号，不是豁免理由。
</EXTREMELY-IMPORTANT>

---

## Verification Escalation Matrix

先定验证级别，再选 Mode — Mode 只决定信息污染程度，不决定是否必须验证。

| Level | 典型场景 | 默认动作 | 允许停在未验证 |
|---|---|---|---|
| V0 | 低风险想法/措辞 | 不必调用 Codex | 可 |
| V1 | 文档/源码可核对事实 | `read-only` 文档核对 | 可，标 `[未验证]` |
| V2 | 本地可执行裁决 | 提出方先验证；必要时升 `workspace-write` | 用户明确接受"先分析" |
| V3 | 破坏性/不可逆操作 | 必须人工/外部验证，不得停在模型共识 | 否 |

V2/V3 无 `[已验证]` → 不得给可直接执行结论。

---

## 三种模式（按信息污染程度）

**先定验证级别（见上方矩阵），再选 Mode — Mode 决定传给 Codex 多少 Claude 的先验信息。**

| 模式 | 传递了什么 | 何时用 |
|---|---|---|
| **Mode B（默认）** | 不传 Claude 结论，真正独立 | 做决定前、方案探索、任何不确定的场景 |
| Mode A（受限） | 传了 Claude 结论，定向审查 | 结论已成型，只需找漏项 |
| Mode C（按需） | 两边交换，短辩论 | 有核心分歧且可被证据裁决 |

### Mode B — Parallel（默认）

不传 Claude 结论，Codex 独立作答；Claude 同步独立作答；完成后综合，标出共识、分歧、采用哪个及原因。

### Mode A — Review（受限，已锚定）

传 Claude 结论，Codex 先独立判断再对比；`[与 Claude 对比]` 必填。

### Mode C — Debate（两轮封顶）

**C1：** 双方独立陈述，每个论点标注 `[可验证]` / `[文档依据]` / `[经验推断]` / `[逻辑假设]`

**C2：** 只针对对方的 `[可验证]` 或 `[文档依据]` 论点反驳；无新证据则终止。

完整 CLI 模板见 [`references/cli-examples.md`](./references/cli-examples.md)

---

## Evidence Packaging Rule

传原始证据包，不传足以替 Codex 预判答案的叙事。

发送前按序检查：
1. **task_to_judge**：一句话描述要判断什么，不写结论或倾向
2. **原始证据**：代码片段 / 原始报错 / 命令输出 / 文档摘录（不传代码解释、错误归因、结论摘要）
3. **known_omissions**：没传但可能影响判断的上下文；无则写 `none`
4. **污染清理**：删除推理过程、风险排序、方案推荐、倾向性形容词

若证据过长：传最小闭包 + 文件路径/行号/复现命令，不得用摘要替代原文。
若 prompt 读起来像"答案草稿"而非"证据包" → 退回重写。

---

## Output Contract

关键结论标注：`[已验证]`（已执行验证）/ `[假设]`（未验证前提）/ `[未验证]`（应验证但未验证；无→写无）。
Mode A 加 `[与 Claude 对比]`；Mode B/C 首轮禁止。无 `[已验证]` 且影响高风险决策 → 置信度不得标 `high`。

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
- 两边结论一致，且下一步属于用户原请求、可逆、可验证 → 直接执行，不再追问"要继续吗？"
- 必须停下问用户：下一步超出原请求 / 缺关键输入 / 不可逆 / 有外部副作用
- 因上述原因未执行 → 收尾中写明阻断原因

---

## 收尾（有实质内容时才写）

只在以下情况写：
- **判断改变**：Codex 让你改变了什么？（没有变化不需要写）
- **验证缺口**：有本应执行但未执行的外部验证？
- **污染风险高**：Prompt 传了 Claude 的推理/结论？
- **learning_signal**：`none` / `trigger-miss` / `trigger-noise` / `mode-error` / `evidence-gap` / `autonomy-gap` / `fact-risk`

三项（判断/缺口/污染）均无且 learning_signal=none → 直接给出综合结论，跳过收尾。
任一有内容 → 简要写出；learning_signal != none → 必须二选一：写 incident 或补一条可回放 eval。

---

## 注意事项

1. 分歧 ≠ Codex 对，是"需要人工判断"的信号
2. 禁止递归：Codex 结论不再交给 Codex 验证
3. 沙盒：默认 `read-only`；需要执行验证时才升 `-s workspace-write`
4. 破坏性/不可逆操作前：必须人工外部验证，不能只靠双模型共识
