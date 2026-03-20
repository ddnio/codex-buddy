# Codex CLI 完整示例

## Mode A — Review（代码/分析审查）

```bash
# 基本审查模式
codex exec -C /Users/nio/project/github-likes/sub2api \
  -s read-only \
  --skip-git-repo-check \
  -o /tmp/codex-review.txt \
  "以下是 Claude 写的代码，请独立审查，找出 bug、安全问题或设计缺陷：

\`\`\`go
<粘贴 Claude 的代码>
\`\`\`

请列出：1) 确定的问题 2) 潜在风险 3) 与 Claude 分析的分歧点"

# 读取结果
cat /tmp/codex-review.txt
```

## Mode B — Parallel（独立并行回答）

```bash
# Codex 独立回答，不受 Claude 影响
codex exec -C /Users/nio/project/github-likes/sub2api \
  -s read-only \
  --skip-git-repo-check \
  -o /tmp/codex-parallel.txt \
  "请独立回答：在 Go 后端中实现支付回调验证，使用 HMAC-SHA256 还是 RSA 公钥验证更好？请给出技术理由。"

# 然后 Claude 也独立回答同一问题，最后综合两个视角
cat /tmp/codex-parallel.txt
```

## Mode C — Debate（多轮辩论，最多 3 轮）

```bash
# 第 1 轮：Claude 答案 → Codex 反驳
codex exec -C /Users/nio/project/github-likes/sub2api \
  -s read-only \
  --skip-git-repo-check \
  -o /tmp/codex-debate-1.txt \
  "Claude 建议将支付状态存储在 Redis 而不是 PostgreSQL，理由是性能更好。
请从数据一致性、持久化、故障恢复角度反驳或补充这个观点。"

# 查看 SESSION_ID（从输出或配置目录获取）
ls -t ~/.codex/sessions/ | head -1

# 第 2 轮：恢复会话，继续辩论
SESSION_ID=$(ls -t ~/.codex/sessions/ | head -1 | sed 's/\.json//')
codex exec resume $SESSION_ID

# 或直接恢复最近一次
codex exec resume --last
```

## 验证命令检查

```bash
# 验证 codex 是否可用
/Users/nio/.nvm/versions/node/v22.21.1/bin/codex --version

# 或通过 PATH（如果已加入）
codex --version

# 检查会话目录
ls ~/.codex/sessions/

# 清理临时输出文件
rm -f /tmp/codex-*.txt
```

## workspace-write 模式（涉及文件操作时）

```bash
# 允许 Codex 读写工作区文件（需告知用户）
codex exec -C /Users/nio/project/github-likes/sub2api \
  -s workspace-write \
  --skip-git-repo-check \
  -o /tmp/codex-write-result.txt \
  "请检查 backend/internal/repository/ 目录下的文件结构，
   分析 easypay_provider.go 的接口实现是否符合 provider 接口约定"
```

## 快速验证（--ephemeral，不保存会话）

```bash
codex exec -C /Users/nio/project/github-likes/sub2api \
  -s read-only \
  --skip-git-repo-check \
  --ephemeral \
  -o /tmp/codex-quick.txt \
  "快速检查：Go 的 context.WithTimeout 和 context.WithDeadline 有什么核心区别？"
```
