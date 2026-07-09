# VerifyUI — Project Guide

> 本文件由 GSD 工作流生成维护。项目上下文见 `.planning/PROJECT.md`,路线图见 `.planning/ROADMAP.md`。

## What This Project Is

前端页面级 AI 验证平台(Electron 桌面应用)。修完问题单或完成需求后,用 AI 解析验证目标、驱动本地 Chrome 执行验证,产出可信的 pass/fail 证据。所有验证手段沉淀成可复用用例库。

## Core Value(命脉)

**即使模型可能判错,验证结论依然可信。** 三条防线:
1. AI 是翻译官和断言生成器,**不是裁判**
2. pass/fail 由**确定性脚本执行**决定,不靠模型判断
3. AI 断言**人工审核后才入库**;Agent **只探索不作裁决**

## Tech Stack

- **外壳**:Electron + electron-vite(主进程 Node.js / 渲染进程 Vue3+Vite+DaisyUI+Pinia)
- **浏览器自动化**:Playwright,**CDP 连接模式**(`connectOverCDP`)附着用户正在运行的 Chrome
- **AI**:内网 Qwen3.6_Dense / deepseek-v4_flash,经 codex 工具,OpenAI 兼容接口
- **存储**:SQLite(better-sqlite3)+ 本地文件系统

## Architecture Constraints

- 浏览器连接**必须用 CDP**,不要用 `launchPersistentContext`(会要求关 Chrome)
- LLM **不直接生成 Playwright 脚本**,生成结构化**验证规约**(JSON)再确定性转译
- 断言**先进"待审核"**,用户确认才入库
- 视觉 Agent 的输出是"证据+候选解释",**归因结论人定**
- 渲染进程纯 UI,重活在主进程,preload 做安全桥接

## Workflow

- 规划文档在 `.planning/`,用 GSD 工作流管理
- 当前:Phase 1(应用骨架与风险探针)未开始
- 运行 `$gsd-discuss-phase 1` 或 `$gsd-plan-phase 1` 开始

## Key Files

| 文件 | 用途 |
|------|------|
| `.planning/PROJECT.md` | 项目定义、约束、决策 |
| `.planning/REQUIREMENTS.md` | 40 条 v1 需求 + 追溯 |
| `.planning/ROADMAP.md` | 10 阶段路线图 |
| `.planning/STATE.md` | 项目记忆/当前状态 |
| `.planning/research/` | 技术研究(STACK/FEATURES/ARCHITECTURE/PITFALLS/SUMMARY) |
