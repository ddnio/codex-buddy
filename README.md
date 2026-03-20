# codex-buddy

> Claude + Codex 跨模型协作验证 skill，每 30 分钟自动迭代进化。

## 核心思想

单一 AI 模型最危险的失效模式不是"不知道"，而是**系统性地、流畅地把错误合理化**。
codex-buddy 通过引入"受控异质性"打破这一闭环：让 GPT-4o（Codex CLI）作为独立审计者，
从不同训练路径、不同 RLHF 偏好出发，对 Claude 的输出进行跨模型验证。

这本质上是给 AI 协作加入工程上的**审计层**和认知上的**去偏层**。

## 三种工作模式

| 模式 | 场景 | 独立性 |
|------|------|--------|
| Mode A — Review | 已有结论，审查执行层错误 | 中（Codex 看到 Claude 答案） |
| Mode B — Parallel | 问题有多个合理解，不希望被污染 | 高（各自独立回答） |
| Mode C — Debate | 高分歧高代价，有可检验依据 | 递进（最多 3 轮，硬性封顶） |

## 安装

```bash
npm install -g @openai/codex
codex --version
```

将 `SKILL.md` 复制到你的 Claude Code skills 目录：

```bash
cp SKILL.md ~/.claude/skills/codex-buddy/SKILL.md
```

## 自动迭代机制

本项目配有 30 分钟自动迭代 cron：
每轮 Claude + Codex 协作讨论一个改进点 → 更新 SKILL.md → commit
迭代日志见 [CHANGELOG.md](./CHANGELOG.md)

## 文件结构

```
codex-buddy/
├── SKILL.md              # 当前 skill 版本（Claude Code 读取）
├── README.md
├── CHANGELOG.md          # 迭代历史
├── references/
│   └── cli-examples.md   # CLI 用法示例
├── discussions/          # 每轮讨论原始记录
└── scripts/
    └── sync-skill.sh     # 同步到实际 skill 路径
```

## 设计原则

1. **独立性优先**：传给 Codex 的上下文需精心控制，避免锚定效应
2. **证据性约束**：分歧点需标注来源（可执行验证 / 文档证据 / 推断）
3. **终止性保证**：Mode C 硬性 3 轮封顶，没有新增证据则提前终止
4. **两模型一致 ≠ 正确**：共识只是"共享训练分布"，真值来自外部验证

## 贡献

迭代由 Claude + Codex 自动驱动，也欢迎手动 PR 改进 SKILL.md。
