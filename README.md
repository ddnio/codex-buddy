# codex-buddy

> A Claude Code skill for cross-model validation via Codex CLI (GPT-4o).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

单一 AI 模型最危险的失效模式不是"不知道"，而是**系统性地、流畅地把错误合理化**。
codex-buddy 通过引入 GPT-4o 作为独立审计者，打破 Claude 的闭环自洽。

**核心原则：两模型一致 ≠ 正确。真值来自外部执行验证。**

---

## 安装

### 前置条件

```bash
npm install -g @openai/codex
codex --version
```

### Claude Code

```bash
git clone https://github.com/ddnio/codex-buddy
cp -r codex-buddy ~/.claude/skills/codex-buddy
```

或使用符号链接（推荐，可跟随仓库更新）：

```bash
ln -s $(pwd)/codex-buddy ~/.claude/skills/codex-buddy
```

### 其他平台

- **Codex CLI**：将 `codex-buddy/` 复制到 `~/.codex/skills/codex-buddy/`
- **Claude.ai**：参考平台文档安装 `.skill` 文件

---

## 使用

skill 会在以下场景自动触发：

| 触发场景 | 原因 |
|---------|------|
| 审查 Claude 自己写的代码 | 避免自我验证盲区 |
| 高风险架构决策 | 多个合理方案需要独立视角 |
| Claude 回答异常流畅 | 越顺畅越可能是在合理化错误 |
| 破坏性操作前 | 不可逆操作必须 double-check |
| 事实接近知识截止点 | 减少幻觉 |

## 三种工作模式

```
Mode A — Review    默认，审查 Claude 产出
    ↓ 发现分歧来自方案空间
Mode B — Parallel  两模型独立回答同一问题
    ↓ 仍有不可解核心分歧
Mode C — Debate    C1 各自陈述 → C2 交换反驳（硬性 2 轮封顶）
```

详细用法和 CLI 示例见 [`references/cli-examples.md`](./references/cli-examples.md)。

---

## 设计哲学

- **受控异质性**：不同训练路径、RLHF 偏好产生真正不同的视角
- **升级链路**：三种模式是渐进升级路径，不是平行选择
- **Prompt 独立性协议**：严格控制传给 Codex 的内容，避免锚定效应
- **真值来源**：运行代码 > 查文档 > 模型共识

设计演进过程见 [`discussions/`](./discussions/)。

---

## 项目结构

```
codex-buddy/
├── SKILL.md              # skill 主文件（安装后 Claude 读取此文件）
├── references/
│   └── cli-examples.md   # 完整 CLI 用法示例
├── discussions/          # 每轮 Claude+Codex 协作讨论记录
├── evals/
│   └── evals.json        # 触发判断测试用例
└── scripts/
    └── sync-skill.sh     # 开发用：同步到本地 skill 路径
```

---

## Contributing

见 [CONTRIBUTING.md](./CONTRIBUTING.md)。
