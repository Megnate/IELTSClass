# Project Research — STACK dimension

**Domain:** 前端页面级 AI 验证平台(Electron 桌面应用)
**Milestone:** Greenfield(从零构建)
**Date:** 2026-07-09

---

## 标准技术栈(2025/2026)

### 桌面应用外壳

| 组件 | 选择 | 版本 | 置信度 | 理由 |
|------|------|------|--------|------|
| **桌面框架** | Electron | ^31+ | 高 | 内网无法用 Rust/Tauri 工具链;Electron 主进程是 Node.js,可直接 spawn/驱动 Playwright。用户已确认 |
| **Node 运行时** | 随 Electron 内置(Node 20+) | — | 高 | 无需单独安装 |

> ⚠️ **不要用**:Tauri(需 Rust,内网不可用)、原生 WebView2 封装(过度复杂)。

### 前端(Vue3 + Vite + DaisyUI,用户指定)

| 组件 | 选择 | 版本 | 置信度 | 理由 |
|------|------|------|--------|------|
| **框架** | Vue 3 | ^3.5 | 高 | 用户指定;Composition API + `<script setup>` |
| **构建** | Vite | ^5+ | 高 | 用户指定;Electron 推荐用 electron-vite 集成 |
| **UI 库** | DaisyUI | ^4 | 高 | 用户指定;基于 Tailwind,组件即 class,轻量 |
| **状态管理** | Pinia | ^2 | 高 | Vue3 官方推荐;比 Vuex 简洁 |
| **路由** | Vue Router | ^4 | 高 | Vue3 标配 |

> 💡 **推荐 `electron-vite`**(而非裸 vite + 手动配 Electron):它把 main/preload/renderer 三端构建、HMR、打包都打通了,省去大量脚手架坑。

### 浏览器自动化(产品命脉)

| 组件 | 选择 | 版本 | 置信度 | 理由 |
|------|------|------|--------|------|
| **自动化引擎** | Playwright | ^1.45+ | 高 | 用户参考的 ai-ready-pw-codegen 即基于此;内置 codegen 录制、断言库、多语言;对 Chrome 支持最好 |
| **连接模式** | `connectOverCDP` | — | 高 | 关键决策(见下) |

**关键决策 —— 如何控制"用户已登录的本地 Chrome":**

研究确认有两条路,必须二选一,且**强烈推荐 CDP 连接模式**:

| 模式 | API | 如何复用登录态 | 致命约束 |
|------|-----|----------------|----------|
| **A. 连接已运行的 Chrome(CDP)✓ 推荐** | `chromium.connectOverCDP(endpoint)` | 用 Chrome 启动时带 `--remote-debugging-port=9222`,Playwright 通过 CDP 接入这个**正在运行**的实例 | 用户需用特定参数启动 Chrome(可由应用帮做) |
| **B. 启动持久化上下文** | `launchPersistentContext(userDataDir)` | 用用户的 Chrome profile 目录启动**新实例** | **必须先关闭该 profile 对应的 Chrome**,否则冲突(GitHub issue #35836) |

**为什么推荐 A(CDP):** 用户日常 Chrome 可能一直开着(登录态、其他标签页),模式 B 要求关掉 Chrome 才能跑验证,体验差且打断工作流。模式 A 让应用"附着"到正在运行的浏览器上,不干扰用户。

> ⚠️ **模式 B 的坑**(已确认):`launchPersistentContext` 若 userDataDir 正被另一个 Chrome 占用,会打开 `about:blank` 而非用户的页面(GitHub microsoft/playwright#35836)。

### AI / LLM 接入(内网模型)

| 组件 | 选择 | 置信度 | 理由 |
|------|------|--------|------|
| **调用方式** | 经 codex 工具 调用内网模型 | 中 | 用户指定;具体接口形态需在 Phase 1 验证 |
| **模型** | Qwen3.6_Dense / deepseek-v4_flash | 中 | 用户提供;flash 偏快精度存疑 → 不可作为最终裁决 |
| **接口封装** | OpenAI 兼容 Chat Completions | 高 | 大多数内网部署(Qwen/deepseek 系)都提供兼容接口,便于抽象 |

**未知风险(Phase 1 必须验证):**
- ❓ 模型是否支持**图像/视觉输入**(决定 AI 视觉 Agent 兜底这条路能否走)
- ❓ codex 工具的具体调用契约(同步/流式、超时、错误码)
- ❓ 上下文窗口大小(影响能塞多少页面 DOM/截图)

### 数据存储(全本地)

| 组件 | 选择 | 置信度 | 理由 |
|------|------|--------|------|
| **结构化数据** | SQLite(better-sqlite3) | 高 | 单文件、无服务、事务可靠;存问题单、验证规约、用例库、术语库、验证记录 |
| **文件证据** | 本地文件系统 | 高 | 截图、快照、生成的 Playwright 脚本文件 |
| **ORM/查询** | Drizzle ORM 或裸 SQL | 中 | Drizzle 类型安全且轻;项目不大也可裸 better-sqlite3 |

> ⚠️ **不要用**:IndexedDB(渲染进程、容量有限、不利于跨进程)、LowDB(并发写不可靠)。

### 录制能力

| 组件 | 选择 | 置信度 | 理由 |
|------|------|--------|------|
| **录制引擎** | Playwright codegen(API) | 高 | Playwright 内置 `codegen`,能录制交互并生成最佳定位器(role/text 优先)。ai-ready-pw-codegen 即基于此 |

> 💡 codegen 生成的是 Playwright 脚本骨架,还需一层**把录制结果转成"验证规约"中间表示**的转换层(产品核心创新点)。

---

## 不使用什么(及原因)

| 不用 | 原因 |
|------|------|
| Tauri | 内网无 Rust 工具链 |
| Puppeteer | Playwright 的 codegen + 断言生态更完整,且用户参考项目基于 Playwright |
| Selenium | 重、需 WebDriver,Playwright 直连 CDP 更轻 |
| browser-use(纯 Python) | 产品前端是 Vue/Electron(Node 生态);可借鉴其 agent loop 思路但用 TS 重写 |
| 远端无头 Chrome 服务 | 碰不到用户本地登录态/内网环境 |

---

## 版本时效性

- Electron 31+:2025 稳定版,Node 20+ 内置 ✓
- Playwright 1.45+:2024 末稳定,connectOverCDP 成熟 ✓
- Vue 3.5 / Vite 5 / DaisyUI 4:均为当前主流稳定版 ✓

> ⚠️ 具体次版本号在 Phase 1 脚手架阶段用 `latest` 锁定,避免训练数据滞后。

---

*Sources: [Playwright BrowserType](https://playwright.dev/docs/api/class-browsertype), [Playwright codegen](https://playwright.dev/docs/codegen), [Playwright Electron API](https://playwright.dev/docs/api/class-electron), [Electron automated testing](https://electronjs.org/docs/latest/tutorial/automated-testing), [Playwright persistent context issue #35836](https://github.com/microsoft/playwright/issues/35836), [browser-use](https://github.com/browser-use/browser-use), [Connect to existing Chrome](https://www.browserstack.com/guide/playwright-connect-to-existing-browser)*
