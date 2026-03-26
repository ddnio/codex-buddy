# STATUS.md

> 仓库状态快照。由 AI 代理在每轮迭代前更新。
> 字段值遵守规定格式，空值写 `NONE`。

---

## skill_version
v1.14.0

## repo_commit
HEAD

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
  title: 确认自主执行规则（SKILL.md L109-114 升级/停止规则）在真实对话中生效
  source: validation_queue V-001
  impact: high
  reversibility: safe
  done_when: "人工确认: 提供至少 2 段真实对话 transcript，其中 1 段显示两边一致+可逆+在请求范围内时代理直接执行（本文件 2026-03-25-w001-validation.md 已提供），1 段显示命中边界条件时代理停止并写明 gate 原因"
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
  done_when: "SKILL.md 含 Output Contract 章节 + Verification Escalation Matrix 章节，且 wc -l SKILL.md | awk '{print $1}' 输出 < 150"
  status: done

- id: W-004
  type: improve
  title: Evidence Packaging Rule（上游污染问题）
  source: deferred_items v1.11+
  impact: high
  reversibility: safe
  done_when: "SKILL.md 含 Evidence Packaging Rule 章节，且 wc -l SKILL.md | awk '{print $1}' < 150"
  status: open

- id: W-005
  type: improve
  title: any conversation 自动触发 + EXTREMELY-IMPORTANT 政策块
  source: 用户提议参考 using-superpowers 设计
  impact: high
  reversibility: safe
  done_when: "SKILL.md description 含 'any conversation'，body 含 EXTREMELY-IMPORTANT 块，wc -l < 150"
  status: done

## selected_item
<!-- 由 AI 从 work_queue 推导；不再人工填写 -->
<!-- 格式: W-xxx；无待办写 NONE -->
W-004

## selection_rationale
<!-- Claude + Codex 综合选题的理由（一句话）；过渡期填 [transition-mode: <Claude 独立判断>] -->
W-005 完成后自然推进 W-004：Evidence Packaging Rule 是下一个高价值改进

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
FIXED
