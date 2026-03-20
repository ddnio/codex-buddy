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
- [ ] Prompt 独立性规范：明确"传什么/不传什么"以避免锚定效应
- [ ] 安装说明：补充多平台安装方式（Claude Code / Claude.ai / Codex CLI）
- [ ] evals：运行触发判断测试，基于结果优化 description
