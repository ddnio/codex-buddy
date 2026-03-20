# CHANGELOG

迭代日志：每轮 Claude + Codex 协作改进记录。

---

## v1.0.0 — 2026-03-20 初始版本

### 内容
- 建立三种工作模式：Mode A（Review）、Mode B（Parallel）、Mode C（Debate）
- 触发判断矩阵
- CLI 参数快速参考

### 来源讨论
Claude + Codex 在 2026-03-20 的首轮 Mode B 分析，两个模型对以下核心设计达成共识：

**已确认的核心洞察（Claude + Codex 双方一致）：**
1. 核心问题是"顺畅陷阱"——越流畅越可能是系统性错误，不是随机噪声
2. N-version programming 类比成立：承认主代理不可信但可用
3. Codex CLI 的执行能力（真实跑命令）比纯语言比较有更高验证价值

**Codex 独立发现的关键缺陷（Claude 未充分强调）：**
1. 多模型一致性 ≠ 正确性，只是共享训练分布
2. Mode A 应审查假设和未验证部分，不只是最终答案
3. 三种模式应建立升级路径（A → B → C），而非平铺并列
4. Mode C 需要"证据类型约束"，防止修辞循环
5. 需要失败模式记录机制，让 skill 从"流程习惯"变成"误差画像系统"

**v1.0 已完成（→ v1.1）：**
- [x] 触发条件从主观感觉改为风险分级规则
- [x] Mode A prompt 模板加入假设/未验证部分审查
- [x] 三种模式改为升级链路设计（A→B→C）
- [x] Mode C 证据类型标注规范

完整讨论记录见 [discussions/2026-03-20-design-philosophy.md](./discussions/2026-03-20-design-philosophy.md)

---

## v1.1.0 — 2026-03-20

### 改进内容
- 触发判断：从"感觉类"改为6项风险分级规则
- 三种模式：升级链路设计（A→B→C），不再平行并列
- Mode A：prompt 增加假设和未验证部分审查
- Mode C：加入4种证据类型标注系统
- 终止规则：无新增证据则提前终止，不强制跑满3轮
- 明确注意事项：两模型一致 ≠ 正确
- references/cli-examples.md：修正 exec resume 语法，补充完整参数速查

### 下轮 Agenda
- [ ] 失败模式记录机制：记录触发原因、发现的问题、哪种模式最有效
- [x] Prompt 独立性规范：明确"传什么/不传什么"以避免锚定效应 → v1.2
- [ ] 安装说明：补充多平台安装方式（Claude Code / Claude.ai / Codex CLI）
- [ ] evals：运行触发判断测试，基于结果优化 description

---

## v1.2.0 — 2026-03-20

**主题：Prompt 独立性规范**
**讨论模式：** Mode B Parallel（Claude + Codex 独立分析后综合）
**完整讨论：** [discussions/2026-03-20-prompt-independence-contract.md](./discussions/2026-03-20-prompt-independence-contract.md)

### 改进内容
- **新增章节 `Prompt 独立性协议`**：四层传递规则 + 五条硬性协议
- **Mode A prompt 重写**：字段隔离结构 + 要求 Codex 先独立重建判断 + Output Contract
- **Mode B prompt 重写**：结构化模板（任务/硬约束/证据/输出要求）
- **Mode C 重设计**：C1（双方独立陈述）→ C2（交换反驳），硬性上限改为 2 轮
- **Abort Rule**：证据不足时先返回"证据不足"，不给结论

### Codex 独立贡献（Claude 未独立发现）
- Mode C 的"反方审稿模式"问题：现在设计是被动反驳，不是真正 Debate
- Abort Rule：Codex 建议的关键缺失，Claude 未想到
- Context Budget 25% 的量化边界

### 下轮 Agenda
- [x] 失败模式记录机制 → v1.3（收尾四问）
- [x] 安装说明：补充多平台安装方式 → v1.4
- [ ] evals：运行触发判断测试，基于结果优化 description
- [ ] Output Contract 模板：为 Codex 输出定义标准格式（事实/假设/建议/未验证）

---

## v1.3.0 — 2026-03-20

**主题：失败模式记录机制**
**讨论模式：** Mode C（3轮，Claude 与 Codex 分歧后收敛）
**完整讨论：** [discussions/2026-03-20-failure-mode-recording.md](./discussions/2026-03-20-failure-mode-recording.md)

### 改进内容
- 新增"收尾四问"章节：Q1 Mode Fit / Q2 Key Divergence / Q3 Verification Gap / Q4 Learning Signal
- 明确触发持久化记录的条件（只在发现真实问题时写 incident 文件）

### Codex 独立贡献
- 三问升四问：加入 Learning Signal，能区分"确认信心"与"真正发现盲点"

---

## v1.4.0 — 2026-03-20

**主题：安装说明多平台**
**讨论模式：** Mode B（并行独立）
**完整讨论：** [discussions/2026-03-20-install-multiplatform.md](./discussions/2026-03-20-install-multiplatform.md)

### 改进内容（README.md）
- Codex CLI 从"其他平台"升为独立安装章节
- 统一 clone 路径，补 `mkdir -p`，用 `"$(pwd)"` 替代拼接路径
- 符号链接 vs 直接复制：说明区别和适用场景
- 新增"验证安装"章节
- 新增"更新"章节
- 删除未经验证的 Claude.ai `.skill` 说法

### Codex 独立发现（纳入下轮）
- description frontmatter 约 750 字符且混入 workflow 说明，违反 skill-creator 规范。应压缩为一句纯触发条件，详细规则留正文

### 下轮 Agenda
- [ ] description 瘦身：压缩 frontmatter 为一句触发条件，正文重新分段
- [ ] evals：运行触发判断测试，基于结果优化 description
- [ ] Output Contract 模板：为 Codex 输出定义标准格式（事实/假设/建议/未验证）
