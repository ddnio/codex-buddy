---
name: codex-buddy
description: Use when reviewing your own code, making high-stakes architecture decisions, verifying facts near your knowledge cutoff, or when your answer feels suspiciously smooth and confident. Also trigger when user explicitly requests cross-model validation. Do NOT trigger for simple tasks, obvious answers, or pure formatting work.
---

# codex-buddy

## Overview

Codex CLI（GPT-4o）作为 AI 伙伴，通过直接调用 `codex exec` CLI 实现跨模型独立验证。核心价值：与 Claude 推理路径互补，训练数据和 RLHF 偏好不同，能真正执行命令验证结果，独立上下文判断更客观。

**前置条件：必须已安装 codex CLI**
```bash
npm install -g @openai/codex
codex --version   # 验证安装
```

---

## 触发判断

### ✅ 应该触发

| 场景 | 原因 |
|---|---|
| 审查 Claude 自己写的代码 | 避免自我验证盲区 |
| 技术方案有重大权衡 | GPT-4o 可能有不同判断 |
| Claude 回答"异常流畅/过于自信" | 越顺畅越可能是在合理化 |
| 需要实际执行命令验证 | Codex 能真正跑命令 |
| 知识截止点附近的事实断言 | 减少幻觉 |
| 用户明确要求跨模型协作 | 直接触发 |

### ❌ 不应触发（节省时间和 token）

简单问答、明确标准答案的任务、纯格式操作、已在 Codex 会话迭代过的内容

---

## 三种工作模式

### Mode A — Review（默认，单次调用）

Claude 产出内容后，调用 Codex 独立审查：

```bash
codex exec -C <项目目录> -s read-only --skip-git-repo-check \
  -o /tmp/codex-review.txt \
  "以下是 Claude 的分析/代码，请独立审查并指出分歧或问题：\n<Claude的输出>"
```

读取 `/tmp/codex-review.txt`，向用户报告分歧点。

**适用：** 代码审查、事实验证、方案 double-check

### Mode B — Parallel（并行独立，单次调用）

不传 Claude 的答案，让 Codex 独立回答同一问题：

```bash
codex exec -C <项目目录> -s read-only --skip-git-repo-check \
  -o /tmp/codex-parallel.txt \
  "请独立回答以下问题：<原始问题>"
```

Claude 自己也独立回答，然后综合两个视角给用户。

**适用：** 技术选型、架构决策

### Mode C — Debate（多轮，硬性封顶 3 轮）

**第 1 轮：** Claude 先答 → 传给 Codex 反驳

```bash
codex exec -C <项目目录> -s read-only --skip-git-repo-check \
  -o /tmp/codex-debate-1.txt \
  "Claude 的观点是：<...>，请从不同角度反驳或补充"
```

**第 2 轮：** 带上 Codex 反驳 → Claude 回应 → 再问 Codex

```bash
# 读取 SESSION_ID 后恢复会话
codex exec resume <SESSION_ID>
# 或恢复最近一次
codex exec resume --last
```

**硬性限制：**
- 最多 3 轮（最多 2 次 codex 调用）
- 每轮后判断是否收敛：若分歧不影响结论则提前终止
- 告知用户本次调用耗时较长

**适用：** 架构决策深度讨论

---

## 使用注意事项

1. **Prompt 精炼**：只传必要上下文，不传完整对话历史
2. **沙盒选择**：默认 `read-only`，涉及文件修改时用 `-s workspace-write` 并告知用户
3. **输出解析**：用 `-o <FILE>` 保存结果，避免解析终端颜色码
4. **分歧解读**：Codex 与 Claude 分歧 ≠ Codex 对，是"需要人工判断"的信号
5. **禁止递归**：Codex 的结论不再交给 Codex 验证

---

## CLI 快速参考

| 参数 | 说明 |
|---|---|
| `-C <DIR>` | 工作目录 |
| `-s read-only` | 只读沙盒（默认） |
| `-s workspace-write` | 可写工作区 |
| `--skip-git-repo-check` | 允许在非 Git 目录运行 |
| `-o <FILE>` | 最终结果写入文件 |
| `--ephemeral` | 不持久化会话 |
| `--json` | 输出 JSONL 格式 |
| `-m <MODEL>` | 指定模型 |

Codex 二进制位置：`/Users/nio/.nvm/versions/node/v22.21.1/bin/codex`

完整 CLI 示例见 `references/cli-examples.md`
