# Codex CLI 完整示例

## 常用参数速查

| 参数 | 说明 |
|------|------|
| `-C <DIR>` | 工作目录（推荐总是指定） |
| `-s read-only` | 只读沙盒（默认，推荐） |
| `-s workspace-write` | 可写工作区（Codex 可修改文件） |
| `-s danger-full-access` | 无沙盒（危险，慎用） |
| `--skip-git-repo-check` | 允许在非 Git 目录运行 |
| `-o <FILE>` | 将最后一条消息写入文件（避免解析终端颜色码） |
| `--ephemeral` | 不持久化会话文件 |
| `--json` | 输出 JSONL 格式（适合程序解析） |
| `-m <MODEL>` | 指定模型（默认 gpt-4o） |
| `--full-auto` | 低摩擦自动模式（`-a on-request --sandbox workspace-write` 的别名） |

---

## Mode A — Review（审查假设 + 结论）

```bash
CODEX_BIN=$(which codex)
PROJECT_DIR="/your/project/path"
OUTPUT_FILE="/tmp/codex-review-$(date +%s).txt"

$CODEX_BIN exec \
  -C "$PROJECT_DIR" \
  -s read-only \
  --skip-git-repo-check \
  -o "$OUTPUT_FILE" \
  "请审查以下 Claude 的产出，重点检查：
1. 结论是否有明显错误
2. 哪些关键假设没有被验证（特别注意隐含前提）
3. 忽略了哪些边界条件或风险点
4. 与你的独立判断有哪些具体分歧

Claude 的产出：
\`\`\`
<粘贴 Claude 的代码或分析>
\`\`\`

请列出：确定问题 / 潜在风险 / 未验证假设 / 与 Claude 的分歧点"

cat "$OUTPUT_FILE"
```

---

## Mode B — Parallel（完全独立，不受 Claude 答案影响）

```bash
CODEX_BIN=$(which codex)
PROJECT_DIR="/your/project/path"
OUTPUT_FILE="/tmp/codex-parallel-$(date +%s).txt"

# 不传 Claude 的答案，让 Codex 独立回答
$CODEX_BIN exec \
  -C "$PROJECT_DIR" \
  -s read-only \
  --skip-git-repo-check \
  -o "$OUTPUT_FILE" \
  "请独立回答以下问题（不参考任何其他模型的意见）：

问题：在 Go 后端中实现支付回调验证，使用 HMAC-SHA256 还是 RSA 公钥验证更好？

请给出：1）推荐方案及技术理由 2）另一方案的适用场景 3）你最担心的实现陷阱"

# Claude 同时独立作答，完成后再综合两个视角
cat "$OUTPUT_FILE"
```

---

## Mode C — Debate 第 1 轮（带证据类型标注）

```bash
$CODEX_BIN exec \
  -C "$PROJECT_DIR" \
  -s read-only \
  --skip-git-repo-check \
  -o /tmp/codex-debate-r1.txt \
  "当前讨论的问题是：微服务间通信使用 gRPC 还是 REST？

Claude 的立场是：对内部服务间通信推荐 gRPC，理由是类型安全和性能更好。

请从不同角度反驳或补充这个观点。
每个论点请标注类型：
- [可执行验证] 可通过运行代码/benchmark 证实
- [文档证据] 有明确文档/RFC/规范支持
- [经验推断] 基于工程经验的合理推断
- [逻辑假设] 纯逻辑推演，未经验证"

cat /tmp/codex-debate-r1.txt
```

---

## 恢复会话（exec resume）

```bash
# 列出最近的会话
ls -t ~/.codex/sessions/ | head -5

# 恢复最近一次会话继续对话
$CODEX_BIN exec resume --last \
  -o /tmp/codex-resume.txt \
  "继续上一轮讨论，针对你提出的第2个论点，Claude 的回应是：<...>"

# 恢复指定会话 ID
$CODEX_BIN exec resume <SESSION_ID> \
  -o /tmp/codex-resume.txt \
  "你的提示"
```

---

## 让 Codex 执行命令验证（workspace-write）

需要 Codex 真正跑命令验证时（比如 benchmark、测试），改用 workspace-write：

```bash
$CODEX_BIN exec \
  -C "$PROJECT_DIR" \
  -s workspace-write \
  --skip-git-repo-check \
  -o /tmp/codex-verify.txt \
  "请运行项目的测试套件，然后告诉我哪些测试失败了以及失败原因"
```

⚠️ workspace-write 允许 Codex 修改文件，使用前告知用户。
