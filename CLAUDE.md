# CLAUDE.md

> 你是在 codex-buddy 仓库中工作的 Claude Code 代理。在做任何操作前读完本文件。

---

## 仓库目标

维护并持续改进 `codex-buddy`——一个让 Claude 与 Codex (GPT-4o) 协作进行跨模型验证的 Claude Code skill。

**唯一真正的产物是 `SKILL.md`**，其他所有文件都服务于它的质量。

---

## 文件职责速查

| 文件/目录 | 职责 |
|-----------|------|
| `SKILL.md` | skill 主体，唯一需要对外发布的文件 |
| `CHANGELOG.md` | 版本记录 + 下轮迭代 Agenda（`[ ]` 列表） |
| `discussions/` | 每轮 Claude+Codex 完整讨论记录，不可删改 |
| `evals/evals.json` | 触发判断测试用例 |
| `references/cli-examples.md` | 完整 CLI 用法示例（供 SKILL.md 引用） |
| `scripts/sync-skill.sh` | 同步 SKILL.md 到本地 skill 安装路径 |
| `logs/incidents/` | 高价值失败案例复盘（可选，按需创建） |

---

## 工具使用

### 1. Codex CLI

调用方式：

```bash
CODEX_BIN=$(which codex)   # 不要硬编码路径
OUTPUT_FILE="/tmp/codex-$(date +%s).txt"

$CODEX_BIN exec \
  -C <工作目录> \
  -s read-only \
  --skip-git-repo-check \
  -o "$OUTPUT_FILE" \
  "<prompt>"

cat "$OUTPUT_FILE"
```

关键参数：

| 参数 | 用途 |
|------|------|
| `-C <DIR>` | 工作目录，必须指定 |
| `-s read-only` | 只读沙盒（默认） |
| `-s workspace-write` | 允许 Codex 写文件（需告知用户） |
| `--skip-git-repo-check` | 非 git 目录也能运行 |
| `-o <FILE>` | 将最后一条消息写入文件（避免终端颜色码干扰） |
| `--ephemeral` | 不持久化会话 |

恢复上一次会话继续对话：

```bash
$CODEX_BIN exec resume --last -o "$OUTPUT_FILE" "<继续的 prompt>"
```

**Prompt 独立性原则（重要）：**
- Mode B / Mode C 第一轮：不传 Claude 的答案，只传原始问题 + 客观证据
- Mode A：先传任务和证据，Claude 观点放在最后单独区块，并要求 Codex 先独立判断再对比
- 禁止传入：Claude 的推理过程、定性结论、倾向性措辞

---

### 2. sync-skill.sh

每次修改 `SKILL.md` 后必须执行，将文件同步到本地 skill 安装路径（即 reload）：

```bash
bash scripts/sync-skill.sh
# 效果：复制 ./SKILL.md → ~/.claude/skills/codex-buddy/SKILL.md
```

---

### 3. git 工作流

```bash
# 每轮迭代完成后
git add -A
git commit -m "feat: v<版本号> - <主题关键词> (Claude+Codex 第N轮迭代)

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
git push
```

提交规范：
- `feat:` 改进 SKILL.md 内容
- `docs:` 改进文档（README、CLAUDE.md、discussions 等）
- `iter:` cron 自动触发的迭代提交

---

### 4. 30 分钟迭代 Cron（session-only）

Cron 在 Claude Code 会话中运行，退出后消失。每轮自动执行完整迭代流程（见下方"迭代流程"）。

重建 cron 时告诉 Claude："帮我重启 codex-buddy 的 30 分钟迭代 cron"，它会读取 CLAUDE.md 中的迭代流程规范并按此设置。

---

## 迭代流程（每轮标准步骤）

### Step 1：确定主题

读取 `CHANGELOG.md` 中最新版本的"下轮 Agenda"，取第一个 `[ ]` 未完成项。

### Step 2：Claude 独立分析

针对该主题，Claude 先给出具体方案（写清楚 SKILL.md 应改哪里、怎么改）。**不要先看 Codex 的答案。**

### Step 3：Codex 独立分析

不传 Claude 的方案，调用 Codex：

```bash
CODEX_BIN=$(which codex)
TIMESTAMP=$(date +%Y%m%d-%H%M)
OUTPUT_FILE="/tmp/codex-iter-${TIMESTAMP}.txt"

$CODEX_BIN exec \
  -C /Users/nio/project/github/codex-buddy \
  -s read-only \
  --skip-git-repo-check \
  -o "$OUTPUT_FILE" \
  "你是 codex-buddy skill 的协作设计者。

当前 SKILL.md 内容：
$(cat SKILL.md)

本轮主题：<主题>

请给出：
1. 针对这个主题，SKILL.md 具体应该改什么（改动前/改动后对比）
2. 这个改动可能引入的新问题
3. 你对当前 skill 最大设计缺陷的独立判断（不限于本轮主题）"

cat "$OUTPUT_FILE"
```

### Step 4：综合两个视角

对比 Claude 和 Codex 的方案：
- 共识点 → 直接采纳
- 分歧点 → 选择并说明理由
- Codex 独立发现的新问题 → 优先考虑纳入

### Step 5：更新文件

```bash
# 1. 修改 SKILL.md（用 Edit 工具）

# 2. 同步到 skill 路径
bash scripts/sync-skill.sh

# 3. 写讨论记录（见下方格式规范）
# 文件名：discussions/YYYY-MM-DD-<topic-slug>.md

# 4. 更新 CHANGELOG.md（追加新版本，更新 Agenda 状态）
```

### Step 6：提交推送

```bash
git add -A
git commit -m "feat: v<版本> - <主题> (Claude+Codex 第N轮迭代)

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
git push
```

---

## discussions/ 格式规范

文件名：`YYYY-MM-DD-<topic-slug>.md`

必须包含以下结构（参考已有文件）：

```markdown
# 讨论：<主题>

**日期：** | **模式：** Mode A/B/C | **结果：** 收敛/分歧

---

## 话题
<问题背景>

---

## 第一轮：各自开场

**Claude：**
> <Claude 的独立观点原文>

**Codex：**
> <Codex 的原始输出>

---

## 第N轮：<轮次描述>
...

---

## 共识与分歧

| 点 | Claude | Codex | 结论 |
|----|--------|-------|------|
...

---

## 对 SKILL.md 的改动
<具体改了什么>
```

**关键要求：Codex 原始输出必须完整保留，不可裁剪或意译。**

---

## 修改 SKILL.md 的禁区

不能破坏：
- 三种模式的名称（Mode A / B / C）及升级链路关系
- Prompt 独立性协议的五条硬性规则
- 收尾四问结构（Q1–Q4）
- 触发判断的风险分级逻辑

---

## 安全边界

- `SKILL.md` 里不写绝对路径，用 `$(which codex)` 代替硬编码
- 不提交私有环境信息、token、用户名
- `discussions/` 里的 Codex 原始输出不可删改
- 冲突时优先级：`SKILL.md` > `CHANGELOG.md` > 其他文档
