# VerifyUI(暂定名)

## What This Is

一个**前端页面级 AI 验证平台**,以 Electron 桌面应用形态运行,用 Vue3 + Vite + DaisyUI 构建前端。它服务于两类场景——**修完问题单后的页面验证**和**需求开发完成后的验收**——两者共享同一套验证引擎和用例库。AI 把人话(问题描述/验收用例)翻译成可在真实 Chrome 里确定性执行的验证规约,跑出 pass/fail 证据,所有规约沉淀成可复用脚本,供开发者自己和他人一键复跑确认。

一句话:让"前端工作完成在页面上"这件事,有可信、可复现、可交付的验证手段。

## Core Value

**即使模型可能判错,验证结论依然可信** —— 准确性是命脉。

这条原则意味着:AI 是翻译官和断言生成器,不是裁判;pass/fail 由确定性脚本执行决定;关键判断(尤其是 AI 生成的断言)需人工确认后才入库;探索型结论不作最终裁决。脚本+断言是可信主干,视觉 Agent 仅作探索兜底。

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] 解析两类输入(自由文本的问题单 / 结构化的需求验收用例)为可执行的页面级验证规约
- [ ] 用例库:存验证规约、可检索、可复用、可一键复跑(这是"别人二次验证"的载体)
- [ ] 术语库:业务词 → 页面URL / 元素定位器的映射,作为 AI 自主解析"该进哪个页面"的命脉
- [ ] 两种验证路径:脚本+断言(可信主干) / 视觉 Agent 探索(兜底,仅探索不作裁决)
- [ ] 断言类型覆盖:功能性(可见/文本/状态)、显示性(CSS/样式)、控制台无 error 报错(一等公民)
- [ ] 录制能力:人录制页面操作 → AI 生成 Playwright 脚本(参考 ai-ready-pw-codegen)
- [ ] 验证结果记录:每条断言 pass/fail + 截图/快照证据,可追溯
- [ ] 引导用户进入待验证页面状态(前置步骤的录制或指引)

### Out of Scope

- 多用户账号系统 / 中心化同步 — 单人本地使用,架构上不堵死未来扩展
- 移动端浏览器 / 非 Chrome — 仅 Chrome
- 后端代码层单元测试 / API 层测试 — 本产品专注页面级,后端测试用现有工具
- 全自动数据制造(让页面进入任意复杂状态) — 前置步骤靠录制或人工指引,不自动造数
- 问题单/工单系统的 API 集成导入 — v1 通过粘贴/上传文本输入

## Context

**背景与动机:**
开发者修改问题单后,常常无法确认"是否改全了"。前端的大量工作发生在页面上,而 AI 编码助手目前只能做到单元测试层面,够不到"操作页面 / 读页面内容 / 查控制台报错 / 看样式对不对"这些页面级验证。这个产品补的就是这个缺口。

**两类触发场景(共享引擎):**
1. **问题单修复验证** —— 输入是自由文本,验收点需 AI 从描述推断。例:
   - "job 页面 wafer 处于 cancel 状态时,unknown 的 wafer 样式应为黑底白字"(回归断言型,脚本强项)
   - "trace 图选某 recipe 信号曲线断了,需定位是后端数据还是前端绘制"(根因诊断型,Agent 探索 + 人工裁决)
2. **需求开发验收** —— 输入更结构化(每步有对应验收用例),验收点已写好,直接落地成规约。这是用例库的主力来源,价值更大(验收是规模化的)。

**能力阶梯(用户的原始构想,经验证为正确顺序):**
术语库(让 AI 听懂该进哪) → AI 解析问题单 → 搜用例库 → 搜不到则录制生成 → 再不行 AI 视觉探索复现。每一级对 AI 要求递增,最高杠杆是术语库。

**技术约束与已知点:**
- 部署:Electron(内网用不了 Rust/Tauri)。主进程 Node.js 直接用 Playwright 控制本地已登录的 Chrome,绕过纯网页前端够不到本地 Chrome 的沙箱限制
- 模型:内网可用,经 codex 工具调用 Qwen3.6_Dense / deepseek-v4_flash(后者偏快、精度需打问号);无限量使用 → 方案必须对"模型可能判错"有抵抗力
- 前端:Vue3 + Vite + DaisyUI(用户指定)
- 模型图像能力是否可用待验证(走 Agent 兜底需要,纯脚本不需要);v1 不依赖图像能力

**参考资料:**
https://github.com/winst0niuss/ai-ready-pw-codegen —— 人录制操作 → AI 生成用例的录制路线。

## Constraints

- **Tech stack**: Electron + Node.js 主进程 + Vue3/Vite/DaisyUI 前端 + Playwright(浏览器自动化) — 内网环境限制,不可用 Rust/Tauri;纯网页前端够不到本地 Chrome
- **Compatibility**: 仅 Chrome — 用户明确指定,不考虑其他浏览器
- **Dependencies**: 内网模型(Qwen3.6_Dense / deepseek-v4_flash,经 codex 工具) — 模型准度不确定,架构必须对此有抵抗力
- **Security/Privacy**: 全本地存储、单用户 — 内网环境,无账号/同步/中心存储
- **Accuracy(核心约束)**: 验证结论可信不押在模型判断上 — AI 是翻译官不是裁判,pass/fail 由确定性执行决定,关键断言需人工确认入库

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Electron 而非 Tauri | 内网无法用 Rust 工具链;Electron 主进程 Node.js 可直接驱动 Playwright | ✓ Good |
| 渐进式:脚本主干 + Agent 兜底 | 准确性靠脚本守住;Agent 满足"自主探索页面"诉求但不作裁决 | — Pending |
| 术语库 = 业务词→页面/元素映射表 | AI 自主解析"该进哪个页面"的命脉,形态确认 | — Pending |
| 全本地单用户 | 当前就一人用;架构预留未来扩展但不为多用户付 v1 成本 | ✓ Good |
| AI 生成的断言需人工确认才入库 | 抵抗模型可能生成错误断言的风险 | — Pending |
| 控制台无 error 检查作为一等公民断言 | 用户明确指出前端验证的核心诉求之一 | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-07-08 after initialization*
