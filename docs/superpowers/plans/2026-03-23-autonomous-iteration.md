# 自主迭代机制 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 codex-buddy 的迭代循环完全由 AI 自主驱动——AI 自己决定方向、与 Codex 讨论、执行提交，人工只在破坏性操作时介入。

**Architecture:** 三层按序实施：(1) 修复 verify-repo.sh 语义检查，防止"叙事先于证据"；(2) 重写 STATUS.md 为显式状态机，让方向选择从人工指令变为状态推导；(3) 重写 WORKFLOW.md Step 1，Claude + Codex 双模型独立排序选题。

**Tech Stack:** bash, YAML-in-Markdown, Codex CLI

**Spec:** `docs/superpowers/specs/2026-03-23-autonomous-iteration-design.md`

**前提：** 所有 bash 命令在仓库根目录执行。脚本内用 `REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"`，脚本外手动设置 `REPO_DIR="$(pwd)"`（确认已在仓库根目录）。

---

## 文件改动清单

| 文件 | 操作 | 层级 |
|------|------|------|
| `scripts/verify-repo.sh` | 修改：新增 CHANGELOG 引用检查 + evals id 连续性 + done_when 主观词汇检查 | 1 |
| `discussions/2026-03-23-trigger-coverage-and-autonomy.md` | 新建：补写 v1.11 缺失的讨论记录 | 1 |
| `STATUS.md` | 重写：新增 work_queue / selected_item / operating_mode / human_gate / last_round_outcome | 2 |
| `references/WORKFLOW.md` | 修改：Step 1 重写为双模型选题；Step 1.5 补充自主模式衔接 | 3 |
| `CLAUDE.md` | 修改：启动顺序第 4 条（next_safe_step → selected_item） | 3 |

---

## Task 1：verify-repo.sh 语义增强

**Files:**
- Modify: `scripts/verify-repo.sh`

- [ ] **Step 1：确认当前检查块结构和 exit 位置**

```bash
REPO_DIR="$(pwd)"
grep -n "echo \"──\|exit \$FAIL" scripts/verify-repo.sh
```

预期：看到若干 `── X ──` 检查块标题行号，以及 `exit $FAIL` 的行号。新内容插入 `exit $FAIL` 之前。

- [ ] **Step 2：在 `exit $FAIL` 之前插入三项新检查**

```bash
# ── 5. CHANGELOG 引用完整性 ────────────────────────────────────
echo "── CHANGELOG 引用完整性 ──"
while IFS= read -r f; do
  if [ -f "$REPO_DIR/$f" ]; then
    pass "引用存在: $f"
  else
    fail "CHANGELOG 引用了不存在的文件: $f"
  fi
done < <(grep -oE 'discussions/[^)]+\.md' "$REPO_DIR/CHANGELOG.md")

# ── 6. evals.json id 连续性 ───────────────────────────────────
echo "── evals.json id 连续性 ──"
if command -v jq &>/dev/null; then
  MAX=$(jq '[.evals[].id] | max' "$REPO_DIR/evals/evals.json")
  COUNT=$(jq '.evals | length' "$REPO_DIR/evals/evals.json")
  if [ "$MAX" = "$COUNT" ]; then
    pass "evals.json id 连续 (1..$COUNT)"
  else
    fail "evals.json id 不连续: max=$MAX, count=$COUNT"
  fi
else
  pass "evals.json id 检查跳过（jq 不可用）"
fi

# ── 7. done_when 主观词汇检查 ─────────────────────────────────
echo "── done_when 主观词汇检查 ──"
if grep -q "done_when" "$REPO_DIR/STATUS.md"; then
  if grep -A1 "done_when" "$REPO_DIR/STATUS.md" | grep -qE 'AI 判断|感觉|认为|满意|觉得'; then
    fail "STATUS.md 的 done_when 包含主观词汇（AI 判断/感觉/认为/满意/觉得）"
  else
    pass "done_when 无主观词汇"
  fi
else
  pass "done_when 检查跳过（STATUS.md 中无 done_when 字段）"
fi
```

- [ ] **Step 3：运行，确认能检测到缺失文件（预期有 FAIL）**

```bash
bash scripts/verify-repo.sh
```

预期输出含：`✗ CHANGELOG 引用了不存在的文件: discussions/2026-03-23-trigger-coverage-and-autonomy.md`

- [ ] **Step 4：提交**

```bash
git add scripts/verify-repo.sh
git commit -m "fix: verify-repo.sh 增加 CHANGELOG 引用完整性 + evals id 连续性 + done_when 主观词汇检查"
```

---

## Task 2：补写缺失的 v1.11 讨论文件

**Files:**
- Create: `discussions/2026-03-23-trigger-coverage-and-autonomy.md`

- [ ] **Step 1：读取 CHANGELOG v1.11 改进内容**

```bash
REPO_DIR="$(pwd)"
grep -A 30 "v1.11.0" "$REPO_DIR/CHANGELOG.md"
```

- [ ] **Step 2：参考已有讨论文件的格式**

```bash
head -50 "$REPO_DIR/discussions/2026-03-21-dev-mechanism-refactor.md"
```

- [ ] **Step 3：创建讨论文件**

文件必须包含以下节（参照 WORKFLOW.md discussions/ 格式规范）：
- 话题（背景）
- 第一轮：各自开场（Claude + Codex 原文）
- 共识与分歧表
- 对 SKILL.md 的改动
- 独立性验证节（包含 Codex 发现了什么 / Claude 因 Codex 改变了什么）

- [ ] **Step 4：运行 verify-repo.sh，确认 PASS**

```bash
bash scripts/verify-repo.sh
```

预期：所有检查 ✓，exit code 0。

- [ ] **Step 5：提交**

```bash
git add discussions/2026-03-23-trigger-coverage-and-autonomy.md
git commit -m "docs: 补写缺失的 v1.11 讨论记录（trigger-coverage-and-autonomy）"
```

---

## Task 3：STATUS.md 重写为显式状态机

**Files:**
- Modify: `STATUS.md`

- [ ] **Step 1：读当前字段，确认迁移内容**

```bash
REPO_DIR="$(pwd)"
cat "$REPO_DIR/STATUS.md"
```

记录 validation_queue 的条目和 deferred_items 的条目。

- [ ] **Step 2：重写 STATUS.md（完整内容）**

```
# STATUS.md

> 仓库状态快照。由 AI 代理在每轮迭代前更新。
> 字段值遵守规定格式，空值写 `NONE`。

---

## skill_version
v1.11.0

## repo_commit
<!-- 每次提交后更新 -->
(run: git rev-parse --short HEAD)

## health_status
<!-- HEALTHY | NEEDS_TRIAGE | BLOCKED -->
HEALTHY

## confirmed_failures
<!-- 格式: [F-ID] 描述 | 证据: <文件:行或讨论链接> | 状态: OPEN|FIXED -->
NONE

## root_cause_hypotheses
<!-- 格式: [H-ID] 假设 | 对应失败: <F-ID> -->
NONE

## work_queue
<!-- 统一待办队列（合并原 validation_queue + deferred_items）
     done_when 必须是可由命令/文件验证的条件，不能是主观判断 -->
- id: W-001
  type: validate
  title: 确认自主执行规则在真实对话中生效
  source: validation_queue V-001
  impact: high
  reversibility: safe
  done_when: "eval 用例可回放且通过；或 human_gate: REQUIRED:missing_input 若无法自动化"
  status: open

- id: W-002
  type: validate
  title: 确认 failure-first 启动顺序在真实对话中有效
  source: validation_queue V-002
  impact: medium
  reversibility: safe
  done_when: "eval 用例可回放且通过；或 human_gate: REQUIRED:missing_input 若无法自动化"
  status: open

- id: W-003
  type: improve
  title: 恢复 Output Contract + Verification Escalation Matrix
  source: deferred_items v1.11+
  impact: medium
  reversibility: safe
  done_when: "SKILL.md 中含 Output Contract 章节 + Verification Escalation Matrix 章节，且 wc -l SKILL.md | awk '{print $1}' 输出 < 150"
  status: open

- id: W-004
  type: improve
  title: Evidence Packaging Rule（上游污染问题）
  source: deferred_items v1.11+
  impact: high
  reversibility: safe
  done_when: "SKILL.md 中含 Evidence Packaging Rule 章节，wc -l SKILL.md | awk '{print $1}' < 150"
  status: open

## selected_item
<!-- 由 AI 从 work_queue 推导；不再人工填写 -->
<!-- 格式: W-xxx；无待办写 NONE -->
NONE

## selection_rationale
<!-- Claude + Codex 综合选题的理由（一句话）；过渡期填 [transition-mode: <Claude 独立判断>] -->
NONE

## operating_mode
<!-- TRIAGE | ITERATE | VALIDATE | BLOCKED -->
ITERATE

## human_gate
<!-- NONE | REQUIRED:<reason> -->
<!-- reason 枚举: destructive / selection_conflict / missing_input / external_side_effect -->
<!-- human_gate != NONE 时：在 STATUS.md 写明阻断原因；cron 场景停止循环并打印阻断信息 -->
NONE

## last_round_outcome
<!-- FIXED | VALIDATED | NO_OP | REGRESSED | UNCERTAIN -->
UNCERTAIN
```

- [ ] **Step 3：验证结构正确性**

```bash
REPO_DIR="$(pwd)"
# next_safe_step 已删除
grep -c "next_safe_step" "$REPO_DIR/STATUS.md"   # 预期: 0
# done_when 数量等于 work_queue 条目数
DONE_WHEN_COUNT=$(grep -c "done_when" "$REPO_DIR/STATUS.md")
QUEUE_COUNT=$(grep -c "^- id:" "$REPO_DIR/STATUS.md")
echo "done_when=$DONE_WHEN_COUNT, work_queue items=$QUEUE_COUNT"
# 预期两者相等
```

- [ ] **Step 4：运行 verify-repo.sh，确认通过（含新的 done_when 检查）**

```bash
bash scripts/verify-repo.sh
```

预期：所有检查 ✓。

- [ ] **Step 5：提交**

```bash
git add STATUS.md
git commit -m "refactor: STATUS.md 重写为显式状态机（work_queue + selected_item + operating_mode）"
```

---

## Task 4：WORKFLOW.md Step 1 重写 + CLAUDE.md 更新

**Files:**
- Modify: `references/WORKFLOW.md`
- Modify: `CLAUDE.md`

- [ ] **Step 1：定位需要修改的位置**

```bash
REPO_DIR="$(pwd)"
grep -n "Step 1\|Step 1.5\|failure-first\|CHANGELOG.*Agenda\|next_safe_step" "$REPO_DIR/references/WORKFLOW.md"
grep -n "next_safe_step" "$REPO_DIR/CLAUDE.md"
```

- [ ] **Step 2：替换 WORKFLOW.md 的 Step 1 内容**

找到现有 `### Step 1：确定主题（failure-first）` 块，替换为：

```
### Step 1：自主选题（双模型方向决策）

**Phase 1A — Claude 独立排序：**
读 `STATUS.work_queue`（仅 status: open 的条目）+ `SKILL.md`，独立列出 top 3 候选 id，每项写：选它的理由 + 如果不选的风险。

**Phase 1B — Codex 独立排序（Mode B，不传 Claude 的排序结果）：**

    CODEX_BIN=$(which codex)
    OUTPUT_FILE="/tmp/codex-direction-$(date +%s).txt"
    REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

    $CODEX_BIN exec \
      -C "$REPO_DIR" \
      -s read-only \
      --skip-git-repo-check \
      -o "$OUTPUT_FILE" \
      "[任务] 从以下 work_queue 中选出最高价值的 top 3 改进项，给出 id 排序和理由
    [约束] 排序标准：failure severity > validation value > autonomy gain > reversibility > effort
    [证据]
    $(cat STATUS.md)
    $(cat SKILL.md)"

    cat "$OUTPUT_FILE"

**Phase 1C — 综合，写入 STATUS.md：**

| 情况 | 行为 |
|------|------|
| 两边 top 1 id 相同 | 写入 `selected_item: W-xxx` |
| top 1 不同但有共同 id | 选共同 id 中优先级最高者 |
| 完全分歧（无共同 id） | `human_gate: REQUIRED:selection_conflict`，停止本轮 |

**过渡期（Phase 1B 未就绪时）：** Phase 1B 可跳过，Phase 1A 单独决定，`selection_rationale` 标注 `[transition-mode]`。
```

- [ ] **Step 3：在 Step 1.5 末尾追加自主模式衔接规则**

在 `### Step 1.5：改动前必答三问` 节的最后追加：

```
**自主模式下：** 三问由 AI 自答，答案必须写入本轮 discussion 文件（不能只停留在对话上下文）。任一问答"否" → 写 `last_round_outcome: NO_OP`，停止本轮，不执行改动。
```

- [ ] **Step 4：更新 CLAUDE.md 启动顺序第 4 条**

将：
```
4. verify 通过 → 按 STATUS.md 的 next_safe_step 开始迭代
```
改为：
```
4. verify 通过 → 运行 WORKFLOW.md Step 1 自主选题（STATUS.md selected_item 若已填则直接用）
```

- [ ] **Step 5：运行 verify-repo.sh 确认通过**

```bash
bash scripts/verify-repo.sh
```

- [ ] **Step 6：提交**

```bash
git add references/WORKFLOW.md CLAUDE.md
git commit -m "feat: WORKFLOW Step 1 重写为双模型自主选题 + Step 1.5 自主模式衔接"
```

---

## Task 5：影子调度测试（层级 3 验收）

**Files:**
- Create: `discussions/2026-03-23-shadow-scheduling-test.md`

- [ ] **Step 1：确认 selected_item 为 NONE**

```bash
REPO_DIR="$(pwd)"
grep "^NONE$\|^W-" "$REPO_DIR/STATUS.md" | head -5
# selected_item 行后面应该是 NONE
```

- [ ] **Step 2：Claude Phase 1A——独立排序**

不接受任何外部主题提示，只读 `STATUS.md` 的 work_queue，独立列出 top 3 id（写入 discussion 草稿）。

- [ ] **Step 3：Codex Phase 1B——独立排序**

```bash
REPO_DIR="$(pwd)"
CODEX_BIN=$(which codex)
OUTPUT_FILE="/tmp/codex-shadow-$(date +%s).txt"

$CODEX_BIN exec -C "$REPO_DIR" -s read-only --skip-git-repo-check \
  -o "$OUTPUT_FILE" \
  "[任务] 从以下 work_queue 中选出最高价值的 top 3 改进项，给出 id 排序和理由
[约束] 排序标准：failure severity > validation value > autonomy gain > reversibility > effort
[证据]
$(cat "$REPO_DIR/STATUS.md")
$(cat "$REPO_DIR/SKILL.md")"

cat "$OUTPUT_FILE"
```

- [ ] **Step 4：比较 top 1 id，写入验收记录**

创建 `discussions/2026-03-23-shadow-scheduling-test.md`，必须包含：

```
Claude top 1: W-xxx
Codex top 1: W-xxx
结论: PASS（id 相同）/ FAIL（分歧，见详情）
```

通过条件：`Claude top 1 id == Codex top 1 id`（字符串相等，无需主观判断）。

- [ ] **Step 5：根据 Phase 1C 规则更新 STATUS.md**

写入 `selected_item` 和 `selection_rationale`。

- [ ] **Step 6：提交**

```bash
git add discussions/2026-03-23-shadow-scheduling-test.md STATUS.md
git commit -m "test: 影子调度测试（层级 3 验收）"
```

---

## Task 6：更新 CHANGELOG 和 STATUS

**Files:**
- Modify: `CHANGELOG.md`
- Modify: `STATUS.md`

- [ ] **Step 1：在 CHANGELOG.md 追加 v1.12 记录**

包含：主题、讨论模式（Mode B）、三个层级的改进内容、Codex 独立贡献、下轮 Agenda。

引用的 discussion 文件须已在前面的 task 中创建（`discussions/2026-03-23-trigger-coverage-and-autonomy.md` 和 `discussions/2026-03-23-shadow-scheduling-test.md`）。

- [ ] **Step 2：运行 verify-repo.sh 确认 CHANGELOG 引用完整**

```bash
bash scripts/verify-repo.sh
```

预期：CHANGELOG 引用完整性检查全部 ✓。

- [ ] **Step 3：更新 STATUS.md**

```
skill_version: v1.12.0
last_round_outcome: VALIDATED
operating_mode: ITERATE
selected_item: NONE  （等待下轮自主选题）
```

- [ ] **Step 4：提交并推送**

```bash
git add CHANGELOG.md STATUS.md
git commit -m "docs: 更新 CHANGELOG v1.12 + STATUS（自主迭代机制上线）"
git push
```
