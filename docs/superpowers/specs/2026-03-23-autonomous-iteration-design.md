# 自主迭代机制设计

**日期：** 2026-03-23
**状态：** 待实施
**目标版本：** v1.12+

---

## 背景

当前 codex-buddy 迭代机制中，"决定做什么"这一步由人工完成（填 STATUS.md 的 `next_safe_step` 或口头告知 Claude）。用户目标是让整个迭代循环完全由 AI 自主驱动：AI 自己决定方向、主动和 Codex 讨论、自己执行提交，人工只在破坏性/不可逆操作时介入。

---

## 核心发现（Claude + Codex Mode B 综合）

1. **调度仍是人工 Agenda 驱动**：`WORKFLOW.md` Step 1 仍读 CHANGELOG 未完成 Agenda；`STATUS.md` 的 `next_safe_step` 是人工手写指令，不是从状态推导的。
2. **"叙事先于证据"根本缺陷**：CHANGELOG 可以声称完成但讨论文件缺失，`verify-repo.sh` 不会发现（只检查文件存在性，不检查 CHANGELOG 引用）。
3. **验证闭环未关闭**：V-001/V-002 依赖"真实对话人工旁观"，无法被 AI 自主确认。

---

## 设计范围

三个改动层级，需按顺序实施。**层级 2→3 的过渡期规则：** 层级 2 完成后、层级 3 上线前，`selected_item` 由当次 AI 在 Phase 1A（Claude 单独判断）中填写，不需要等 Phase 1B（Codex 参与）就绪。过渡期内 `selection_rationale` 标注 `[transition-mode]`。

---

## 层级 1：修复"叙事先于证据"（前提）

### verify-repo.sh 语义增强

新增两项检查：

```bash
# 检查 CHANGELOG 中引用的 discussions/ 文件是否真实存在
echo "── CHANGELOG 引用完整性 ──"
grep -oE 'discussions/[^)]+\.md' "$REPO_DIR/CHANGELOG.md" | while read f; do
  if [ -f "$REPO_DIR/$f" ]; then
    pass "引用存在: $f"
  else
    fail "CHANGELOG 引用了不存在的文件: $f"
  fi
done

# 检查 evals.json 中的 id 是否为 1..N 连续无缺失
echo "── evals.json id 连续性 ──"
if command -v jq &>/dev/null; then
  MAX=$(jq '[.evals[].id] | max' "$REPO_DIR/evals/evals.json")
  COUNT=$(jq '.evals | length' "$REPO_DIR/evals/evals.json")
  if [ "$MAX" = "$COUNT" ]; then
    pass "evals.json id 连续 (1..$COUNT)"
  else
    fail "evals.json id 不连续：max=$MAX, count=$COUNT"
  fi
else
  pass "evals.json id 检查跳过（jq 不可用）"
fi
```

**验收条件：**
- `bash scripts/verify-repo.sh` 在 CHANGELOG 引用了缺失 discussion 文件时报 FAIL
- 修复缺失的 `discussions/2026-03-23-trigger-coverage-and-autonomy.md`（v1.11 声称存在但仓库没有）

---

## 层级 2：STATUS.md → 显式状态机

### 新 Schema

将 `validation_queue`、`deferred_items`、`next_safe_step` 合并为统一 `work_queue`，新增状态控制字段：

```yaml
## work_queue
# 每项必须有 done_when 条件——且 done_when 必须是可由外部证据验证的陈述，
# 不能是"AI 判断满意"类主观描述（自我评分护栏）
- id: W-001
  type: validate          # validate | fix | improve | explore
  title: <简短标题>
  source: <来源：CHANGELOG vX.X / Codex 发现 / validation_queue>
  impact: high | medium | low
  reversibility: safe | risky | destructive
  done_when: "<可由文件/命令输出/eval 结果验证的条件，不是主观满意度>"
  status: open            # open | selected | in_progress | done | dropped

## selected_item
# 由 AI 从 work_queue 推导，不再人工填写
W-xxx

## selection_rationale
# Claude + Codex 综合选题的理由（一句话）；过渡期填 [transition-mode]

## operating_mode
ITERATE   # TRIAGE | ITERATE | VALIDATE | BLOCKED

## human_gate
NONE      # NONE | REQUIRED:<reason>
# reason 枚举：destructive / selection_conflict / missing_input / external_side_effect
# human_gate != NONE 时：在 STATUS.md 中写明阻断原因；cron 场景下停止循环并打印阻断信息

## last_round_outcome
UNCERTAIN # FIXED | VALIDATED | NO_OP | REGRESSED | UNCERTAIN
```

### done_when 护栏规则

`done_when` 字段必须满足以下任一形式，否则 AI 不得将 status 标记为 done：
- **命令可验证**：`bash scripts/verify-repo.sh` 通过 / `diff` 无输出 / eval 测试通过
- **文件可验证**：指定文件存在且包含指定内容
- **人工确认门**：明确写 `done_when: "人工确认: <具体条件>"`，此时 `human_gate` 自动置 `REQUIRED:missing_input`

### 迁移规则

| 旧字段 | 迁移到 |
|--------|--------|
| `validation_queue` | `work_queue`（type: validate） |
| `deferred_items` | `work_queue`（status: open，impact: low） |
| `next_safe_step` | 删除，由 `selected_item` + `selection_rationale` 替代 |

**验收条件（可自动检查）：**
- `grep -c "next_safe_step" STATUS.md` 输出 0
- `grep -c "done_when" STATUS.md` 等于 work_queue 条目数
- 每条 done_when 不含"AI 判断"/"感觉"/"认为"等主观词汇（verify-repo.sh 可 grep 检查）

---

## 层级 3：WORKFLOW.md Step 1 重写（自主选题）

### 新 Step 1：方向决策（两阶段）

**Phase 1A — Claude 独立排序：**
读 `STATUS.work_queue` + `SKILL.md`，独立列出 top 3 候选，每项写：选它的理由 + 如果不选的风险。

**Phase 1B — Codex 独立排序（Mode B，不传 Claude 的排序）：**

```bash
$(which codex) exec -C <项目目录> -s read-only --skip-git-repo-check \
  -o /tmp/codex-direction-$(date +%s).txt \
  "[任务] 从以下 work_queue 中选出最高价值的 top 3 改进项，给出排序和理由
[约束] 排序标准：failure severity > validation value > autonomy gain > reversibility > effort
[证据]
$(cat STATUS.md)
$(cat SKILL.md)"
```

**Phase 1C — 综合：**

| 情况 | 行为 |
|------|------|
| top 1 id 相同 | 直接写入 `selected_item` |
| top 1 不同但有共同 id | 选共同 id 中优先级最高者 |
| 完全分歧（无共同 id） | `human_gate: REQUIRED:selection_conflict`，停止本轮 |

写入 `STATUS.selected_item` + `selection_rationale` 后进入 Step 1.5。

### Step 1.5 与自主模式的衔接

当前 Step 1.5（改动前三问）在自主模式下由 AI 自答，**答案必须写入本轮 discussion 文件**，不能只停留在对话上下文。三问若有任何一问答案为"否"，写 `last_round_outcome: NO_OP`，停止本轮，不执行改动。

### 停止条件

| 情况 | `last_round_outcome` | 后续行为 |
|------|----------------------|----------|
| Codex 无新发现 | NO_OP | 停止本轮 |
| done_when 满足（外部可验证） | VALIDATED | 标记 done，selected_item → 下一项 |
| done_when 未满足 | UNCERTAIN | 保留 selected，下轮继续 |
| 变更破坏性/不可逆 | — | `human_gate: REQUIRED:destructive`，停止循环打印阻断信息 |
| 两边结论一致且可逆 | — | 直接执行，不问用户 |

### 影子调度测试（层级 3 验收）

**操作化定义：**
1. 清空 `STATUS.selected_item`（或填 NONE）
2. 不给 Claude 任何主题提示，只给 `STATUS.md`
3. Claude 独立完成 Phase 1A，输出 top 3 id 列表
4. Codex 独立完成 Phase 1B，输出 top 3 id 列表
5. **通过条件**：两个列表的 top 1 id 相同（不需要人工判断"哪个更好"，只需比较 id 字符串相等）
6. 结果写入 discussion 文件，作为层级 3 的验收证据

---

## 实施顺序

1. **层级 1**：增强 `verify-repo.sh` + 补写缺失的 v1.11 discussion 文件（前提，先做）
2. **层级 2**：重写 `STATUS.md` schema + 迁移现有条目（过渡期规则见文件顶部）
3. **层级 3**：重写 `WORKFLOW.md` Step 1 + 跑影子调度测试验收

---

## 未解决问题

- V-001/V-002 的"真实对话验证"能否变成可回放 eval。若可以，其 `done_when` 为"eval 通过"；若不可以，`done_when` 必须写 `"人工确认: ..."` 并触发 human_gate。
