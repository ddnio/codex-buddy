# codex-buddy

> A Claude Code skill for cross-model verification via Codex CLI.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

单一 AI 模型最危险的失效模式不是"不知道"，而是**系统性地、流畅地把错误合理化**。
codex-buddy 通过引入 Codex 作为独立审计者，打破 Claude 的闭环自洽。

**核心原则：两模型一致 ≠ 正确。真值来自执行验证，不来自模型共识。**

---

## 安装

### 通用前置条件

```bash
npm install -g @openai/codex
codex --version

git clone https://github.com/ddnio/codex-buddy.git
cd codex-buddy
```

### Claude Code

Claude Code 从 `~/.claude/skills/` 加载 skills。

**推荐：符号链接**（`git pull` 后自动生效）

```bash
mkdir -p ~/.claude/skills
ln -s "$(pwd)" ~/.claude/skills/codex-buddy
```

**或：直接复制**（更稳定，更新时需手动重新复制）

```bash
mkdir -p ~/.claude/skills
cp -R "$(pwd)" ~/.claude/skills/codex-buddy
```

### Codex CLI

Codex CLI 从 `~/.codex/skills/` 加载 skills。

```bash
mkdir -p ~/.codex/skills
ln -s "$(pwd)" ~/.codex/skills/codex-buddy
```

### 其他环境

将整个 `codex-buddy/` 目录复制到该宿主的 skills 路径下，至少保证包含：

```
codex-buddy/
├── SKILL.md
└── references/
```

### 验证安装

```bash
# 检查 Codex CLI
codex --version

# 按实际环境检查 skill 路径
ls ~/.claude/skills/codex-buddy/SKILL.md   # Claude Code
ls ~/.codex/skills/codex-buddy/SKILL.md    # Codex CLI
```

> 如果是已打开的会话，建议重启后再测试 skill 触发。

### 更新

```bash
cd codex-buddy && git pull
# 使用符号链接时自动生效
# 使用 cp 安装时需重新执行 cp 命令
```

---

## 使用

安装后，skill 在每次对话开始时自动加载，建立会话级验证政策。**加载 ≠ 自动调用 Codex**，而是让 Claude 每个回合判断是否需要跨模型验证。

### 验证级别（V0–V3）

每个回合，Claude 会在回复开头标注验证级别：

| 级别 | 场景 | 动作 |
|------|------|------|
| V0 | 低风险/机械任务 | 不调 Codex |
| V1 | 文档/源码可核对的事实 | 可选核对，跳过标 `[未验证]` |
| V2 | 需要执行验证的判断 | 必须先验证再给结论 |
| V3 | 破坏性/不可逆操作 | 必须人工/外部验证 |

### 对话协议

需要调用 Codex 时，对话按以下协议自然流转：

```
Probe（默认首步）— 不传 Claude 结论，两模型独立回答，综合共识与分歧
  ↓ Codex 有疑问或信息不足
Follow-up — 补充原始证据回应 Codex 追问，仍不传 Claude 结论
  ↓ 有具体分歧且可被证据裁决
Challenge — 针对编号 claim (C1/C2/...) 提出反证，不重写整篇答案
```

**裁决规则：** 分歧可验证 → 直接验证，不辩论。无法验证 → 标 `[unresolved]`，交给用户。最多 2 次 Codex 调用，未收敛就停。

详细用法和 CLI 示例见 [`references/cli-examples.md`](./references/cli-examples.md)。

---

## 设计哲学

- **受控异质性**：不同训练路径产生真正不同的视角
- **证据打包**：传原始证据，不传 Claude 的推理过程和倾向性措辞，避免锚定效应
- **渐进升级**：Probe → Follow-up → Challenge 是按需升级路径，不是平行选择
- **真值来源**：运行代码 > 查文档 > 模型共识

设计演进过程见 [`discussions/`](./discussions/)。

---

## 项目结构

```
codex-buddy/
├── SKILL.md              # skill 主文件（唯一产物，安装后 AI 读取此文件）
├── references/
│   ├── cli-examples.md   # 完整 Codex CLI 用法示例
│   └── WORKFLOW.md       # 开发者迭代流程手册
├── discussions/          # 每轮 Claude+Codex 协作讨论记录
├── evals/
│   └── evals.json        # 触发判断测试用例（18 条）
├── scripts/
│   ├── sync-skill.sh     # 开发用：同步到本地 skill 路径
│   └── verify-repo.sh    # 仓库健康检查（11 项自动化校验）
├── STATUS.md             # 项目状态快照（work queue + 调度）
└── CHANGELOG.md          # 历史版本记录
```

---

## Contributing

见 [CONTRIBUTING.md](./CONTRIBUTING.md)。
