# Requirements: VerifyUI

**Defined:** 2026-07-09
**Core Value:** 即使模型可能判错,验证结论依然可信 —— AI 是翻译官和断言生成器,不是裁判;pass/fail 由确定性脚本执行决定;关键断言需人工确认入库;Agent 只探索不作裁决。

## v1 Requirements

v1 覆盖完整闭环:断言型(脚本主干) + 诊断型(Agent 兜底)。按路线图分阶段实现。

### 应用外壳与基础设施

- [ ] **SHELL-01**: Electron + Vue3 + Vite + DaisyUI 应用能启动运行(electron-vite 脚手架,主进程+渲染进程+preload)
- [ ] **SHELL-02**: 应用能引导/代为启动带 `--remote-debugging-port` 的本地 Chrome(检测已启动则直接连接)
- [ ] **SHELL-03**: 设置页:配置内网模型端点(codex 工具)、Chrome 路径、数据目录
- [ ] **SHELL-04**: 本地数据持久化(SQLite via better-sqlite3 + 文件系统存截图/脚本)

### Chrome 连接与执行

- [ ] **CONN-01**: 通过 CDP(`connectOverCDP`)附着到用户正在运行的 Chrome,复用登录态,不要求关闭浏览器
- [ ] **EXEC-01**: 执行验证规约:把规约转译成 Playwright 操作序列并在本地 Chrome 跑
- [ ] **EXEC-02**: 确定性断言判定:pass/fail 由执行决定,不依赖模型判断
- [ ] **EXEC-03**: 控制台 error / pageerror 捕获,作为一条一等公民断言
- [ ] **EXEC-04**: 每步截图/快照取证,断言失败时尤其保留
- [ ] **EXEC-05**: 验证脚本显式绑定到特定 tab(按 URL 匹配或新建),避免误操作用户其他标签页

### 输入与解析

- [ ] **PARSE-01**: 文本粘贴输入:粘贴问题单文本 / 需求验收用例文本
- [ ] **PARSE-03**: AI 解析自由文本为结构化字段(验证目标 / 涉及页面 / 涉及元素 / 期望结果 / 验收点)
- [ ] **PARSE-04**: 自动分类路由:判断问题单是"断言型"(走脚本主干)还是"诊断型"(走 Agent 探索)
- [ ] **PARSE-05**: AI 解析结果可编辑 / 可纠错(用户可改 AI 拆出来的字段)

### 术语库(命脉)

- [ ] **GLOSS-01**: 术语 CRUD:每条 {术语, 别名[], 目标URL, 入口路径, 关键元素定位器[]}
- [ ] **GLOSS-02**: 术语检索:AI 解析问题时按词命中术语库,返回对应页面/定位器
- [ ] **GLOSS-03**: 别名/同义词管理(同一页面多种叫法,如"工单列表"/"ticket list")
- [ ] **GLOSS-04**: 术语命中可视化:解析时高亮问题单里被命中的词,让用户看到 AI 用了哪些映射

### 验证规约引擎(命门)

- [ ] **SPEC-01**: 规约数据模型:统一中间表示(导航/前置/操作/断言集/证据规范),与执行引擎解耦
- [ ] **SPEC-02**: 导航步骤:术语库把"去 job 页面"解析成 URL 导航
- [ ] **SPEC-03**: 前置步骤:支持录制或人工指引让页面进入待验证状态(造数据/走流程)
- [ ] **SPEC-04**: AI 断言生成:把"黑底白字""控制台无报错"翻译成具体可执行断言
- [ ] **SPEC-05**: 断言分类:功能性(toHaveText/toBeVisible/状态) / 显示性(toHaveCSS) / 控制台无 error
- [ ] **SPEC-06**: 断言人工审核入库:AI 生成的断言先进"待审核"态,用户确认无误才入库(守准确性命脉)
- [ ] **SPEC-07**: 规约可读化展示:给用户看人话版"这个用例验什么",而非纯代码

### 用例库

- [ ] **CASE-01**: 用例存储:一份验证规约 = 一条用例
- [ ] **CASE-02**: 用例检索:按页面 / 术语 / 关键词 / 标签
- [ ] **CASE-03**: 用例一键执行:选中用例 → 在本地 Chrome 跑 → 出 pass/fail
- [ ] **CASE-04**: 用例与来源(问题单 / 需求)关联,可追溯

### 录制能力

- [ ] **REC-01**: 在本地 Chrome 上启动录制用户操作
- [ ] **REC-02**: 生成稳健定位器(role/text 优先,基于 Playwright codegen)
- [ ] **REC-03**: 录制结果转成验证规约中间表示(而非裸脚本)
- [ ] **REC-04**: 录制时提示用户插入断言

### AI 视觉 Agent 探索(兜底 —— 仅探索不作裁决)

- [ ] **AGENT-01**: Agent 循环:截图 → 视觉模型分析 → 决定下一步操作 → 执行 → 循环
- [ ] **AGENT-02**: 探索复现诊断型问题(如"trace 曲线断了,定位前后端")
- [ ] **AGENT-03**: Agent 只探索不作裁决:输出证据 + 候选解释,最终归因由人定
- [ ] **AGENT-04**: 探索成功后引导沉淀成脚本规约入库,下次走可信主干

### 验证记录

- [ ] **LOG-01**: 每次执行留记录:时间 / 用例 / 每条断言结果 / 证据
- [ ] **LOG-02**: 结果展示:pass/fail 总览 + 详情 + 截图
- [ ] **LOG-03**: 失败诊断:给出"实际值 vs 期望值"对比 + 截图证据

## v2 Requirements

### 输入与解析(增强)

- **PARSE-02**: 文件上传输入(.md / .txt / .docx / .xlsx),解析后入库

### 用例库(增强)

- **CASE-05**: 用例导出为独立 Playwright 脚本文件,可脱离本应用运行(真·交给别人一键跑)
- **CASE-06**: 用例版本化:页面改版导致定位器失效时保留历史版本
- **CASE-07**: 用例标签/分组:按功能模块、环境、优先级

### 验证记录(增强)

- **LOG-04**: 历史追溯:某用例的历史执行曲线
- **LOG-05**: 回归对比:改完再验,对比上次结果

## Out of Scope

| Feature | Reason |
|---------|--------|
| 多用户账号系统 / 中心化同步 | 当前单人本地使用;架构预留未来扩展但不为多用户付 v1 成本 |
| 移动端浏览器 / 非 Chrome 支持 | 用户明确仅 Chrome |
| 后端代码层单元测试 / API 层测试 | 本产品专注页面级验证,后端测试用现有工具 |
| 全自动制造任意复杂页面状态 | 前置步骤靠录制或人工指引,自动造数太复杂且不可靠 |
| 工单系统(Jira/Tapd/飞书)API 集成导入 | v1 通过粘贴文本输入,API 集成推后 |
| 术语库自动从代码/DOM 反推 | 太脆且不准,人工维护更可靠 |
| Agent 作最终 pass/fail 裁决 | 准确性命脉,不押在模型判断上 |
| 用例云同步 / 团队共享 | 单用户本地,v2+ 再考虑 |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SHELL-01 | Phase 1 | Pending |
| SHELL-02 | Phase 1 | Pending |
| SHELL-03 | Phase 1 | Pending |
| SHELL-04 | Phase 1 | Pending |
| CONN-01 | Phase 1 | Pending |
| EXEC-01 | Phase 6 | Pending |
| EXEC-02 | Phase 6 | Pending |
| EXEC-03 | Phase 6 | Pending |
| EXEC-04 | Phase 6 | Pending |
| EXEC-05 | Phase 6 | Pending |
| PARSE-01 | Phase 5 | Pending |
| PARSE-03 | Phase 5 | Pending |
| PARSE-04 | Phase 5 | Pending |
| PARSE-05 | Phase 5 | Pending |
| GLOSS-01 | Phase 4 | Pending |
| GLOSS-02 | Phase 4 | Pending |
| GLOSS-03 | Phase 4 | Pending |
| GLOSS-04 | Phase 4 | Pending |
| SPEC-01 | Phase 6 | Pending |
| SPEC-02 | Phase 6 | Pending |
| SPEC-03 | Phase 7 | Pending |
| SPEC-04 | Phase 6 | Pending |
| SPEC-05 | Phase 6 | Pending |
| SPEC-06 | Phase 6 | Pending |
| SPEC-07 | Phase 6 | Pending |
| CASE-01 | Phase 8 | Pending |
| CASE-02 | Phase 8 | Pending |
| CASE-03 | Phase 8 | Pending |
| CASE-04 | Phase 8 | Pending |
| REC-01 | Phase 7 | Pending |
| REC-02 | Phase 7 | Pending |
| REC-03 | Phase 7 | Pending |
| REC-04 | Phase 7 | Pending |
| AGENT-01 | Phase 9 | Pending |
| AGENT-02 | Phase 9 | Pending |
| AGENT-03 | Phase 9 | Pending |
| AGENT-04 | Phase 9 | Pending |
| LOG-01 | Phase 10 | Pending |
| LOG-02 | Phase 10 | Pending |
| LOG-03 | Phase 10 | Pending |

**Coverage:**
- v1 requirements: 40 total
- Mapped to phases: 40
- Unmapped: 0 ✓

---
*Requirements defined: 2026-07-09*
*Last updated: 2026-07-09 after initial definition*
