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

**先按验证矩阵确定验证级别，再按任务性质选 Mode。** Mode 决定 Claude 与 Codex 如何交换观点；验证级别决定谁负责外部验证、是否升级沙盒。顺序不可颠倒。

| 场景 | 选 Mode |
|---|---|
| 需要独立第一意见（执行决策前、方案探索） | **Mode B**（默认独立模式） |
| Claude 结论已成型，只做定向审查/找漏项 | Mode A（受限，非默认） |
| 已出现可检验的核心分歧 | Mode C |
| V2/V3 影响执行：先定验证动作 | Mode B 辅助验证；**禁用 Mode A 作首轮** |

### Mode A — Review（受限，非默认）

Codex 在看见 Claude 结论后做**定向审查**，不是完全独立判断。仅当 Claude 结论已成型且目标是找漏洞/边界条件时使用：

```bash
$(which codex) exec -C <项目目录> -s read-only --skip-git-repo-check \
  -o /tmp/codex-review-$(date +%s).txt \
  "[原始任务] <用户问题>
[可用证据] <代码/报错/日志>
[项目背景] <技术栈、系统边界>
[Claude 待审观点] <Claude 的结论/假设>

先基于任务和证据独立判断，再与 Claude 对比。
使用 Output Contract 标准输出模板，[与 Claude 对比] 字段必填。"
```

**适用：** 已成型结论的代码审查、结论补漏、风险盘点
**禁用：** V2/V3 首轮、方案探索、执行决策前的独立判断

### Mode B — Parallel（默认独立模式）

不传 Claude 答案，先获得真正独立的 Codex 判断，再由 Claude 综合。优先用于：执行决策前、方案探索、V1/V2 需要避免先验结论污染的场景：

```bash
$(which codex) exec -C <项目目录> -s read-only --skip-git-repo-check \
  -o /tmp/codex-parallel-$(date +%s).txt \
  "[任务] <用户原始问题>
[硬约束] <技术栈、限制>
[可用证据] <相关片段>
使用 Output Contract 标准输出模板，禁止出现 [与 Claude 对比] 字段。"
```

Claude 同步独立作答，完成后综合：标出共识、分歧、采用哪个及原因。

**适用：** 独立判断、方案探索、执行前判断、架构取舍 | **升 C 的信号：** 有可检验的核心分歧

### Mode C — Debate（两轮封顶）

**C1：** 双方各自独立陈述立场，每个论点标注：`[可执行验证]` / `[文档证据]` / `[经验推断]` / `[逻辑假设]`

```bash
$(which codex) exec -C <项目目录> -s read-only --skip-git-repo-check \
  -o /tmp/codex-c1.txt \
  "就以下问题给出独立立场。使用 Output Contract 标准输出模板，
在每条 [事实]/[已验证]/[假设] 后额外标注：[可执行验证]/[文档证据]/[经验推断]/[逻辑假设]
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

七条硬规则：Context Order（问题>证据>背景>Claude观点）/ Context Budget（Claude观点≤25%）/ Verification First（先定验证级别，再选 Mode）/ Mode-A Boundary（任务目标是"获得独立判断"时禁用 Mode A；V2/V3 禁用 Mode A 作首轮）/ Escalation Rule（按验证矩阵决定是否升级）/ Output Contract（必须使用下文标准输出模板）/ Abort Rule（证据不足先返回缺失清单）

---

## Verification Escalation Matrix（验证责任矩阵）

先按场景选级别，再决定是否调用 Codex、是否升级沙盒。

| Level | 典型场景 | 验证责任 | 默认沙盒 | 可停于未验证的条件 |
|---|---|---|---|---|
| V0 | 思路补充、措辞改写、非事实建议 | 无需外部验证 | read-only | 不影响实际执行决策 |
| V1 | 文档可核对的事实、API/CLI 用法 | Claude 或 Codex 任一完成文档核对 | read-only | 已列出缺失证据且不用于高风险操作 |
| V2 | 本地可执行验证：测试/重现 bug/dry-run | 提出主张的一方先承担最小验证责任 | workspace-write（需执行时升级） | 用户明确接受"分析不执行"，且输出保留 `[未验证]` 和最小验证动作 |
| V3 | 破坏性/不可逆操作：删数据/生产变更/权限修改 | **必须人工外部验证** | 不得让 Codex 代执行 | **不允许**，只能输出"停止执行 + 缺失验证清单" |

责任规则：① 提出会影响决策的主张的一方先承担最小验证责任；② `workspace-write` 只用于本地可安全完成的 V2 验证；③ V3 验证需要真实外部系统、不可逆副作用时，不升级给 Codex，转交人工。

Mode 约束：V2 影响执行时优先 Mode B + 最小外部验证，不得先 Mode A 再决定是否验证；V3 禁用 Mode A，只能输出"停止执行/移交人工"或用 Mode B 做风险枚举（不传 Claude 结论）。

---

## Output Contract（标准输出模板）

Codex 每次调用必须使用以下固定结构输出；Claude 只从这些字段提取结论，不从自由段落猜测。

```
[验证级别] V0 / V1 / V2 / V3
[验证责任] Claude / Codex / 双方 / 人工
[升级决策] stay-read-only / escalate-workspace-write / handoff-human
[结论] <一句话主结论> | 置信度：high / medium / low
[事实] F1. <输入中可直接观察的事实，标注来源：代码/日志/文档>
[已验证] V1. <已执行外部验证的结果> | 验证方式：命令/测试/文档核对 | 结果：pass/fail/observed
         若无 → 明确写：无
[假设] A1. <影响结论但仍未验证的前提>
       若无 → 明确写：无
[建议] R1. <建议动作> 依据：F#/V#/A#
[未验证] U1. <本应验证但未验证的点> 建议验证：<最小外部验证动作>
          若无 → 明确写：无
[与 Claude 对比]  ← 仅 Mode A 填写
  一致：<结论/事实/假设层面的一致点>
  分歧：D1. <分歧点> 类型：结论/假设/证据解释 | 我方依据：F#/V#/A# | 需要的裁决验证：<最小动作>
```

约束：① `事实` 禁止掺入推断；② `已验证` 禁止"我认为/根据经验"等表述；③ `假设`/`未验证` 不得留空，无则写"无"；④ `建议` 必须引用 F#/V#/A#；⑤ 无 `已验证` 且结论依赖关键假设时 `置信度` 不得为 `high`；⑥ `验证级别` 为 V2/V3 且 `已验证` 为"无"时，`升级决策` 不得为 `stay-read-only`，除非 `结论` 明确为"停止执行/移交人工"。

模板外补充说明允许存在，但关键结论必须落在模板字段内。

## Claude 提取规则

读取 Codex 输出时的字段映射：`已验证` → 最强证据 / `事实` → 已观察但未必外部验证 / `假设` → 仍待裁决的前提 / `未验证` → 直接进入 Q3 Verification Gap / `分歧` → 直接进入 Q2 Key Divergence。禁止把 `建议` 提升为 `事实`，禁止从模板外文本提炼关键结论。

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
2. 沙盒：默认 `read-only`；V2 验证且动作在本地工作区可安全完成时才升 `-s workspace-write`；V3 操作不得让 Codex 代执行，转交人工
3. 分歧 ≠ Codex 对，是"需要人工判断"的信号
4. 禁止递归：Codex 结论不再交给 Codex 验证
5. 真值来源：执行验证 > 文档 > 模型共识

完整 CLI 示例见 [`references/cli-examples.md`](./references/cli-examples.md)
