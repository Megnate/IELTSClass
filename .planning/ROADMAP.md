# Roadmap: VerifyUI

**Created:** 2026-07-09
**Granularity:** Fine(10 phases)
**Mode:** Standard
**Project Mode:** standard

依赖顺序严格遵循研究结论:外壳 → Chrome 连接 → 数据层 → 术语库 → 输入解析 → 规约引擎+执行(核心闭环) → 录制 → 用例库 → Agent 兜底 → 验证记录。两个致命未知在 Phase 1 作为显式探针验证。

---

## Phase Overview

| # | Phase | Goal | Requirements | UI |
|---|-------|------|--------------|----|
| 1 | 应用骨架与风险探针 | 能启动应用、连上本地 Chrome、验证模型能力 | SHELL-01/02/03/04, CONN-01 | yes |
| 2 | 术语库 | 维护"业务词→页面/定位器"映射并检索 | GLOSS-01/02/03/04 | yes |
| 3 | 输入解析与分类 | AI 把文本拆成结构化字段并判类型 | PARSE-01/03/04/05 | yes |
| 4 | 验证规约引擎核心 | LLM 生成规约与断言,人工审核入库 | SPEC-01/02/04/05/06/07 | yes |
| 5 | 脚本执行与取证 | 规约在 Chrome 跑出 pass/fail + 证据 | EXEC-01/02/03/04/05 | partial |
| 6 | 录制能力 | 人录操作 → 生成规约(补前置步骤) | REC-01/02/03/04, SPEC-03 | yes |
| 7 | 用例库 | 规约存库、检索、一键执行、追溯 | CASE-01/02/03/04 | yes |
| 8 | AI 视觉 Agent 探索(兜底) | 诊断型问题靠 Agent 探索 + 人工归因 | AGENT-01/02/03/04 | yes |
| 9 | 验证记录与失败诊断 | 每次执行留痕、展示、失败诊断 | LOG-01/02/03 | yes |
| 10 | 端到端打通与打磨 | 两场景闭环可演示,真实问题单跑通 | (集成验证) | yes |

---

### Phase 1: 应用骨架与风险探针
**Goal:** 搭起 Electron+Vue3 应用,能通过 CDP 连上用户本地已登录的 Chrome,并验证两个致命未知(模型能力 / Electron 打包后 CDP),为后续扫清最大风险。
**UI hint**: yes
**Requirements:** SHELL-01, SHELL-02, SHELL-03, SHELL-04, CONN-01
**Success Criteria:**
1. 应用启动后显示 Vue3+DaisyUI 界面,设置页可配置模型端点/Chrome 路径/数据目录,配置持久化
2. 点击"连接 Chrome",应用通过 CDP 附着到用户正在运行的 Chrome,界面显示连接的标签页(URL 标题),不要求用户关闭浏览器
3. 应用能代为启动带 `--remote-debugging-port=9222` 的 Chrome(若未启动)
4. **风险探针 A**:向内网模型发一次测试请求,报告其是否支持图像输入、上下文窗口大小、调用是否稳定 —— 结论写入设置页
5. **风险探针 B**:应用打包后(非仅开发模式)仍能 CDP 连接 Chrome —— 验证 Playwright 二进制不打包进 asar 的方案

---

### Phase 2: 术语库
**Goal:** 用户能维护"业务词 → 页面URL / 元素定位器"的映射表,并提供检索接口供后续 AI 解析调用。这是 AI 自主解析"该进哪个页面"的命脉。
**UI hint**: yes
**Requirements:** GLOSS-01, GLOSS-02, GLOSS-03, GLOSS-04
**Success Criteria:**
1. 术语 CRUD 界面:新增/编辑/删除术语条目,每条含 {术语, 别名[], 目标URL, 入口路径, 关键元素定位器[]}
2. 别名管理:同一页面可挂多个叫法,任一叫法都能命中
3. 检索 API:给定一段文本,返回命中的术语及其页面/定位器映射(供 Phase 3 调用)
4. 命中可视化:对一段示例文本高亮命中的术语并显示其映射目标
5. 至少录入一批真实种子术语(来自用户的实际被测项目页面)

---

### Phase 3: 输入解析与分类
**Goal:** 用户粘贴问题单/需求用例文本,AI 拆成结构化字段(验证目标/涉及页面/元素/期望结果/验收点),并自动判断是"断言型"还是"诊断型"路由到对应路径。结果可编辑。
**UI hint**: yes
**Requirements:** PARSE-01, PARSE-03, PARSE-04, PARSE-05
**Success Criteria:**
1. 粘贴问题单1(wafer 样式黑底白字)→ AI 输出结构化字段,涉及页面经术语库命中"job 页面"
2. 粘贴问题单2(曲线断定位前后端)→ AI 正确判为"诊断型",路由标记为 Agent 路径
3. 解析结果以可编辑表单展示,用户可改任一字段后保存
4. 解析时高亮命中的术语(复用 Phase 2 可视化)
5. 解析失败(模型不给力)时,提供结构化手填兜底入口

---

### Phase 4: 验证规约引擎核心
**Goal:** 把解析出的结构化字段转成可执行的验证规约(导航+断言集),AI 生成断言,人工审核确认后才入库。这是产品的命门 —— 守住准确性。
**UI hint**: yes
**Requirements:** SPEC-01, SPEC-02, SPEC-04, SPEC-05, SPEC-06, SPEC-07
**Success Criteria:**
1. 规约数据模型定义清晰(JSON schema:导航/前置占位/操作/断言集/证据规范),与执行引擎解耦
2. 给定"job 页面 wafer cancel 状态 unknown 黑底白字",AI 生成导航(经术语库) + 断言集(background-color=黑, color=白)
3. 断言分类正确:功能性 / 显示性(CSS) / 控制台无 error 三类可区分
4. **AI 生成的断言先进"待审核"态,用户逐条确认/修改后才标记为"已确认"** —— 未确认断言不进执行
5. 规约以人话版展示("验证 job 页面 cancel 状态 wafer 的 unknown 元素:背景黑、文字白、控制台无错"),用户看得懂

---

### Phase 5: 脚本执行与取证
**Goal:** 把已审核规约转译成 Playwright 操作序列,在本地 Chrome 跑出确定性 pass/fail,捕获控制台错误,留截图证据。**这是核心闭环跑通的里程碑。**
**UI hint**: partial
**Requirements:** EXEC-01, EXEC-02, EXEC-03, EXEC-04, EXEC-05
**Success Criteria:**
1. 选中一条已审核规约 → 点击执行 → 在 Chrome 跑完整序列 → 输出每条断言 pass/fail
2. pass/fail 由确定性执行决定,不调用模型判断
3. 控制台 error/pageerror 被捕获并作为一条断言参与判定(控制台有 error → 该条 fail)
4. 每步留截图;断言失败时额外保留实际 computedStyle/文本值
5. 执行显式绑定到特定 tab(按 URL 匹配),不影响用户其他标签页;执行前提示"正在控制被测标签"

---

### Phase 6: 录制能力
**Goal:** 用户能在本地 Chrome 录制操作,生成稳健定位器并转成规约(尤其用于"前置步骤"——让页面进入待验证状态,这是实际验证最常卡的地方)。
**UI hint**: yes
**Requirements:** REC-01, REC-02, REC-03, REC-04, SPEC-03
**Success Criteria:**
1. 点击"开始录制" → 在本地 Chrome 操作 → 停止后得到操作序列,定位器为 role/text 优先(Playwright codegen)
2. 录制结果转成规约前置/操作步骤(中间表示),非裸脚本
3. 录制过程中可插入断言(提示用户"此处加断言?")
4. 前置步骤可作为可复用片段,被多个用例引用
5. 用问题单1的真实流程录一遍"如何进到有 cancel 状态 wafer 的 job 页面",成功生成前置

---

### Phase 7: 用例库
**Goal:** 规约沉淀成可复用用例,可按多维度检索、一键执行、追溯到来源。这是"别人二次验证"的载体(导出脚本在 v2)。
**UI hint**: yes
**Requirements:** CASE-01, CASE-02, CASE-03, CASE-04
**Success Criteria:**
1. 已审核规约可"保存为用例",存入用例库
2. 用例列表可按页面/术语/关键词/标签检索过滤
3. 选中用例 → 一键执行 → 出 pass/fail(复用 Phase 5 执行引擎)
4. 用例关联其来源问题单/需求,可反向追溯
5. 同类问题单再来时,检索命中已有用例直接执行,无需重新生成

---

### Phase 8: AI 视觉 Agent 探索(兜底)
**Goal:** 诊断型问题(如曲线断了定位前后端)靠视觉 Agent 探索复现,收集证据给出候选解释,但**最终归因由人定**(Agent 不作裁决)。探索成功后引导沉淀成脚本规约。
**UI hint**: yes
**Requirements:** AGENT-01, AGENT-02, AGENT-03, AGENT-04
**Success Criteria:**
1. Agent 循环运行:截图 → 视觉模型分析 → 决定操作 → 执行 → 循环,过程可在 UI 观察
2. 对问题单2(曲线断),Agent 能抓取 API 响应/DOM/截图等多源证据,汇总呈现
3. **Agent 输出为"证据 + 候选解释(可能后端/可能前端)",pass/fail 归因由用户确认**,Agent 不下结论
4. 探索跑通的流程可引导沉淀成脚本规约入库,下次走可信主干
5. (若 Phase 1 探针发现模型不支持图像)该阶段启用 fallback:纯 DOM 文本 + 用户手动指引探索

---

### Phase 9: 验证记录与失败诊断
**Goal:** 每次执行留完整记录,清晰展示结果与证据,失败时给出"实际值 vs 期望值"诊断,帮助快速定位。
**UI hint**: yes
**Requirements:** LOG-01, LOG-02, LOG-03
**Success Criteria:**
1. 每次执行自动生成记录:时间 / 关联用例 / 每条断言结果 / 截图证据,存 SQLite
2. 验证记录列表 + 详情视图:pass/fail 总览,点开看每条断言与截图
3. 失败诊断:明确显示"期望 X,实际 Y"+ 失败处截图,区分"真 bug"与"定位器失效"
4. 记录可追溯到对应用例与来源问题单
5. (基础)同一用例的历史执行记录可查看

---

### Phase 10: 端到端打通与打磨
**Goal:** 两个场景(问题单修复验证 / 需求验收)端到端可演示,用真实问题单跑通全流程,补齐集成缝隙与体验问题。
**UI hint**: yes
**Requirements:** (集成验证,覆盖全部 v1 需求)
**Success Criteria:**
1. 场景A(问题单):贴问题单1 → 解析 → 命中用例或生成规约 → 审核 → 执行 → 出 pass/fail + 证据,全流程无断点
2. 场景A(诊断型):贴问题单2 → 判诊断型 → Agent 探索 → 证据汇总 → 人工归因 → 沉淀
3. 场景B(需求验收):录入结构化验收用例 → 落规约 → 执行 → 结果,全流程无断点
4. "别人二次验证":另一台机器装应用 → 导入用例库 → 一键执行复现结果
5. Phase 1 两个风险探针的结论在最终架构中得到正确处理(模型无图像则 Agent 走 fallback 等)

---

## Coverage Summary

- v1 requirements: 40 total
- Mapped to phases: 40 ✓
- Unmapped: 0
- Out of scope: 8(见 REQUIREMENTS.md)

---
*Roadmap created: 2026-07-09*
