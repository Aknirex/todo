# 05 — LLM 适配 + Agent 全链路

**What to build:** 用户可配置 LLM API Key（BYOK 模式），执行 AI 拆解（文本→Todo）和 AI 总结（Todo→文本）。包含 OpenAI 兼容适配器、Prompt 模板、AgentStore、设置页（含 DeepSeek/Mimo 入门引导）、拆解页、总结页。

**Blocked by:** 02 — 状态管理层

**Status:** ready-for-agent

- [ ] OpenAI 兼容 LLM 适配器（支持 DeepSeek / Mimo / 通用 OpenAI 兼容）
- [ ] 文本→Todo 拆解 Prompt + JSON 解析
- [ ] Todo→文本总结 Prompt
- [ ] AgentStore: 配置管理 + decomposeText + summarizeTodos
- [ ] 设置页：LLM Provider 选择、API Key 输入、BaseUrl、Model 配置
- [ ] 首次使用 Agent 功能时检测未配置 Key → 展示入门引导页
- [ ] 入门引导：DeepSeek 图文指引（注册步骤、充值入口、费用说明）
- [ ] 入门引导：小米 Mimo 图文指引
- [ ] 拆解页：粘贴文本 → 点击"拆解" → 预览结构化 todo 列表 → 确认保存
- [ ] 总结页：选择列表 → 点击"总结" → 展示汇总文本 → 可编辑/复制
- [ ] LLM 调用超时 30 秒 → 提示重试
- [ ] API Key 无效 → 提示重新配置
