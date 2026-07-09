# Project Research Summary

**Project:** VerifyUI(前端页面级 AI 验证平台)
**Date:** 2026-07-09
**Research basis:** STACK / FEATURES / ARCHITECTURE / PITFALLS(本目录)

---

## Key Findings(给路线图的关键输入)

### 技术栈(确定性高)
- **外壳**:Electron(主进程 Node.js)+ Vue3 + Vite + DaisyUI + Pinia。用 **electron-vite** 脚手架打通三端。
- **浏览器自动化**:Playwright,**CDP 连接模式**(`connectOverCDP`)附着到用户正在运行的 Chrome,而非 `launchPersistentContext`(后者要求关 Chrome,体验灾难)。
- **录制**:Playwright 内置 codegen,生成稳健定位器(role/text 优先)。
- **AI**:内网 Qwen3.6_Dense / deepseek-v4_flash,经 codex 工具,OpenAI 兼容接口封装。**图像能力未知 → Phase 1 先探针**。
- **存储**:SQLite(better-sqlite3)+ 本地文件(截图/脚本)。

### 核心架构决策(必须坚持)
1. **规约引擎作中间层**:LLM 不直接生成脚本,而是生成结构化规约(JSON),再确定性转译成 Playwright 调用。可读、可审核、可复用、可存库。
2. **断言人工审核入库**:AI 断言先进"待审核",用户确认才生效。守准确性命脉。
3. **Agent 只探索不裁决**:视觉 Agent 输出证据+候选解释,归因由人定。
4. **输入分类路由**:问题单自动判"断言型/诊断型",分别走脚本/Agent。

### 必备功能(table stakes,影响 v1 范围)
- 文本粘贴/文件上传输入 + AI 解析(含分类路由)
- 术语库 CRUD + 检索(命脉)
- 验证规约引擎(导航/前置/操作/断言/控制台错误/取证)
- 用例库(存/检索/一键执行)
- 录制能力(补前置步骤)
- Playwright CDP 执行 + 断言判定 + 控制台错误捕获 + 截图取证
- 验证记录存储与展示
- Electron 外壳 + Chrome 启动辅助 + 设置页

### 差异化(可分阶段)
- 用例导出为独立 Playwright 脚本(真·交给别人)
- 术语自动学习、别名管理、命中可视化
- 录制时插入断言、前置片段复用
- 失败诊断(实际值 vs 期望值)、回归对比
- AI 视觉 Agent 兜底探索

---

## Implications for Roadmap(路线图含义)

### MVP 核心 = 闭环跑通
最小可观测价值是:**贴一张断言型问题单 → AI 解析+术语命中 → 生成规约(人工审核断言)→ 在本地 Chrome 跑 → 出 pass/fail + 截图**。在此之前所有组件都是铺垫,之后才是增强。

### 强依赖序决定阶段切分
研究得出的构建顺序(外壳→Chrome连接→数据层→术语库→输入解析→规约引擎+执行→用例库→录制→取证→Agent→记录深化)有强依赖,**路线图必须遵循此序**,不能乱跳。细粒度配置下,这正好切成多个小阶段。

### Phase 1 必须包含"风险探针"
两个致命未知**必须在第一阶段验证**,否则后续架构可能返工:
- 内网模型的**图像能力 / 上下文窗口 / 调用稳定性**(P6)
- Playwright **在 Electron 打包后能否 CDP 连接**(P7)

这两个探针应作为 Phase 1 的显式成功标准,而非隐藏假设。

### "诊断型"路径可后置
用户的问题单2(曲线断、定位前后端)是诊断型,走 Agent 探索。但脚本主干(断言型)价值更高、覆盖面更广(需求验收基本都是断言型)。**路线图先做断言型主干,Agent 兜底放后面阶段**。这与"渐进式全做"不矛盾——全做,但有先后。

### 术语库是早期重点
术语库决定 AI 能否自主解析"该进哪个页面",是后续输入解析、用例检索、规约导航的基础。应在主干闭环前就建立可用规模,建议在术语库阶段就结合用户的真实页面录入一批种子术语。

---

## Watch Out For(三大风险,贯穿全程)

1. **准确性命脉(P3/P4)**:任何让模型当裁判的设计都要拒绝。断言审核 + Agent 不裁决 + 确定性执行,三条防线缺一不可。
2. **前置步骤(P5)**:实际验证最常卡在这里。优先录制路线,前置片段可复用,不追求自动造数。
3. **模型能力假设(P6)**:图像/窗口/稳定性三个未知,Phase 1 探针先验证,架构据此调整。脚本主干对图像零依赖 → 即便图像不可用,产品仍成立。

---

## Sources

- [Playwright BrowserType / connectOverCDP](https://playwright.dev/docs/api/class-browsertype)
- [Playwright codegen](https://playwright.dev/docs/codegen)
- [Playwright persistent context issue #35836](https://github.com/microsoft/playwright/issues/35836)
- [Playwright in Electron — StackOverflow #76851093](https://stackoverflow.com/questions/76851093/playwright-not-launching-within-electron-app)
- [Electron automated testing](https://electronjs.org/docs/latest/tutorial/automated-testing)
- [browser-use vision agent 模式](https://github.com/browser-use/browser-use)
- [Connect to existing Chrome — BrowserStack](https://www.browserstack.com/guide/playwright-connect-to-existing-browser)
- 用户提供的两个问题单样本(断言型 + 诊断型)
- ai-ready-pw-codegen 录制路线参考

---
*Research synthesized: 2026-07-09*
