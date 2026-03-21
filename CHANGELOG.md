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
- [x] description 瘦身：压缩 frontmatter 为一句触发条件，正文重新分段 → v1.5
- [ ] evals：运行触发判断测试，基于结果优化 description
- [ ] Output Contract 模板：为 Codex 输出定义标准格式（事实/假设/建议/未验证）

---

## v1.5.0 — 2026-03-20

**主题：description 瘦身**
**讨论模式：** Mode A（Claude 先独立方案，Codex 独立审查）
**完整讨论：** [discussions/2026-03-20-description-trim.md](./discussions/2026-03-20-description-trim.md)

### 改进内容
- description 从 ~750 字符压缩至 ~280 字符，删除 workflow 解释
- 保留 5 个核心触发信号：代码审查 / 架构决策 / 知识截止点 / 破坏性操作 / 流畅度警告
- 措辞改为 action-oriented："reviewing code you just wrote"（不是"code you just wrote and want reviewed"）
- 符合 skill-creator 规范：description 只描述"何时触发"，策略规则留正文

### Codex 独立发现（纳入下轮）
- Body 缺少 **Output Contract**：各 Mode 的 Codex 输出没有统一格式约定，是当前最大设计缺口
- 建议定义：独立结论 / 与 Claude 一致点 / 分歧点 / 已验证 / 未验证

### 下轮 Agenda
- [x] **Output Contract 模板**：为 Codex 输出定义标准格式 → v1.6
- [ ] evals：运行触发判断测试，基于结果优化 description
- [ ] body 结构优化：按 skill-creator 推荐的「触发/模式选择/CLI 模板/事后复盘」重新分段

---

## v1.6.0 — 2026-03-20

**主题：Output Contract 标准输出模板**
**讨论模式：** Mode A（Claude 先独立方案，Codex 独立审查）
**完整讨论：** [discussions/2026-03-20-output-contract.md](./discussions/2026-03-20-output-contract.md)

### 改进内容
- **新增 `## Output Contract（标准输出模板）`**：7 字段结构（结论/事实/已验证/假设/建议/未验证/与Claude对比）+ 6 条约束 + 缓冲条款
- **新增 `## Claude 提取规则`**：字段映射关系，防止 Claude 从自由文本猜结论
- **`五条硬规则`**：Output Contract 从抽象原则改为指向具体模板章节
- **Mode A/B/C prompt 更新**：各追加 Output Contract 使用要求，Mode B/C 首轮明确禁止 [与 Claude 对比] 字段
- SKILL.md 行数：119 → 149 行（+30 行）

### Codex 独立发现（纳入下轮）
- **验证责任定义太虚**：当前 skill 没有回答"谁来执行验证、何时升级沙盒、何时允许停在未验证"，容易被用成"再问一次另一个模型"而不是真正的异质性校验。需要 `Verification Escalation Matrix`。

### 下轮 Agenda
- [x] **Verification Escalation Matrix** → v1.7
- [ ] evals：运行触发判断测试，基于结果优化 description
- [ ] body 结构优化：按 skill-creator 推荐的四段式重新分段

---

## v1.7.0 — 2026-03-20

**主题：Verification Escalation Matrix（验证责任矩阵）**
**讨论模式：** Mode A（Claude 先独立方案，Codex 独立审查）
**完整讨论：** [discussions/2026-03-20-verification-escalation-matrix.md](./discussions/2026-03-20-verification-escalation-matrix.md)

### 改进内容
- **新增 `## Verification Escalation Matrix`**：V0-V3 四级验证矩阵 + 3 条责任规则
- **工作模式入口**：加"先按验证矩阵确定验证级别，再选 Mode"提示（防止 skill 退化为纯语言模型对比）
- **六条硬规则**：新增 `Verification First`（先定验证级别，再选 Mode）
- **Output Contract 模板**：顶部加 `[验证级别][验证责任][升级决策]` 三字段
- **约束 ⑥**：V2/V3 且无 `已验证` 时 `升级决策` 不得为 `stay-read-only`
- **沙盒说明**：从提示升级为规则，V3 明确转交人工
- SKILL.md 行数：149 → 169 行（+20 行）

### Codex 独立发现（纳入下轮）
- **Mode A 默认值的锚定风险**：只要 Claude 的结论已进 prompt，Codex 独立性就会被削弱，skill 容易运行成"受控的复述与补充"。应该先判定验证级别，再决定是否用 Mode A。

### 下轮 Agenda
- [x] **Mode A 锚定风险** → v1.8
- [ ] evals：运行触发判断测试，基于结果优化 description
- [ ] body 结构优化：按 skill-creator 推荐的四段式重新分段

---

## v1.8.0 — 2026-03-20

**主题：Mode A 锚定风险**
**讨论模式：** Mode A（Claude 先独立方案，Codex 独立审查）
**完整讨论：** [discussions/2026-03-20-mode-a-anchoring.md](./discussions/2026-03-20-mode-a-anchoring.md)

### 改进内容
- **工作模式入口**：升级链路改为 Mode 选择器决策表，V2/V3 明确禁用 Mode A 作首轮
- **Mode A**：`Review（默认）` → `Review（受限，非默认）`，加禁用场景（V2/V3 首轮、方案探索、执行决策前独立判断）
- **Mode B**：`Parallel（独立并行）` → `Parallel（默认独立模式）`，明确优先使用场景
- **七条硬规则**：新增 `Mode-A Boundary`（任务目标是获得独立判断时禁用 Mode A；V2/V3 禁用）
- **Verification Matrix**：末尾加 Mode 约束注释
- SKILL.md 行数：169 → 177 行（+8 行）

### Codex 独立发现（纳入下轮）
- **Evidence Packaging Rule（证据打包规则）**：Claude 控制哪些证据传给 Codex，这是比 Mode A 更上游的锚定问题。代码片段 > 代码解释，原始报错 > 错误归因，命令输出 > 结论摘要。即使用了 Mode B，如果传的是"处理过的证据叙事"，异质性还是假的。

### 下轮 Agenda
- [x] **description 主轴重写 + 收尾四问改条件触发 + Red Flags** → v1.9
- [ ] **Evidence Packaging Rule**：证据打包规则（Codex 指出这是所有 Mode 都面临的上游污染问题，比 Mode A 降级更根本）
- [ ] evals：运行触发判断测试，验证新 description 在 meta 场景的召回率
- [ ] body 结构优化：按 skill-creator 推荐的四段式重新分段

---

## v1.9.0 — 2026-03-21

**主题：description 主轴重写 + 收尾改为条件触发 + Red Flags**
**讨论模式：** Mode B × 2（触发失败根因分析 + superpowers 设计对比）
**完整讨论：** [discussions/2026-03-21-description-trigger-redesign.md](./discussions/2026-03-21-description-trigger-redesign.md)

### 改进内容
- **description 主轴改变**：从"内省信号"（before trusting your own answer / fluency）改为"任务信号"（needs independent second-model verification）
- **meta 场景显式化**：加入"when asked to assess this skill itself or explain why it did or did not trigger"，覆盖之前两次漏触发的盲区
- **fluency 从 description 降级**：不再作为触发条件（后验信号，触发时刻根本不可用）；设计哲学保留在正文
- **收尾四问 → 条件触发**：三项均无（判断未变/无验证缺口/无污染风险）则跳过，避免模板式填空
- **新增 Red Flags 章节**：4 条合理化借口 + 对应现实，防止执行层漏触发

### Codex 独立贡献（Claude 未独立发现）
- "后验 vs 前验"的诊断：`fluency` 在 description 匹配时刻根本不存在，是架构层面错误不只是措辞问题
- "封闭枚举"问题：枚举越强，未枚举的近邻场景越容易漏
- `"If being wrong would be costly"` 总兜底公式

### 下轮 Agenda
- [ ] **Evidence Packaging Rule**：证据打包规则
- [ ] evals：验证新 description 在 meta 场景、隐式 paraphrase 场景的召回率
- [ ] body 结构优化
