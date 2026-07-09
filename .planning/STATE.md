# Project State: VerifyUI

**Last updated:** 2026-07-09
**Current phase:** Phase 1 — 应用骨架与风险探针(未开始)

---

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-07-09)

**Core value:** 即使模型可能判错,验证结论依然可信 —— AI 是翻译官不是裁判,pass/fail 由确定性执行决定,断言需人工审核,Agent 只探索不作裁决。
**Current focus:** Phase 1 — 搭 Electron+Vue3 骨架,CDP 连本地 Chrome,验证两个致命未知(模型能力 / Electron 打包后 CDP)

---

## Roadmap Status

| Phase | Name | Status | Plans |
|-------|------|--------|-------|
| 1 | 应用骨架与风险探针 | ○ Pending | 0/0 |
| 2 | 术语库 | ○ Pending | 0/0 |
| 3 | 输入解析与分类 | ○ Pending | 0/0 |
| 4 | 验证规约引擎核心 | ○ Pending | 0/0 |
| 5 | 脚本执行与取证 | ○ Pending | 0/0 |
| 6 | 录制能力 | ○ Pending | 0/0 |
| 7 | 用例库 | ○ Pending | 0/0 |
| 8 | AI 视觉 Agent 探索(兜底) | ○ Pending | 0/0 |
| 9 | 验证记录与失败诊断 | ○ Pending | 0/0 |
| 10 | 端到端打通与打磨 | ○ Pending | 0/0 |

**Progress:** 0/10 phases · 0/40 requirements complete

---

## Active Decisions & Constraints

- **部署**:Electron(内网无 Rust,不可 Tauri);主进程 Node.js 驱动 Playwright
- **浏览器连接**:`connectOverCDP` 附着用户正在运行的 Chrome(非 launchPersistentContext,后者要求关浏览器)
- **准确性三防线**:① 断言人工审核入库 ② Agent 不作裁决 ③ pass/fail 确定性执行
- **模型**:内网 Qwen3.6_Dense / deepseek-v4_flash 经 codex 工具;图像能力未知 → Phase 1 探针
- **规约中间层**:LLM 生成结构化规约(JSON),非直接生成脚本
- **范围**:单用户本地;v1 含诊断型 Agent;导出脚本(CASE-05)/文件上传(PARSE-02)推 v2

---

## Open Risks(Phase 1 必须验证)

1. **模型图像能力 / 上下文窗口 / 稳定性**(P6)—— 决定 Agent 兜底能否走视觉路径
2. **Playwright 在 Electron 打包后能否 CDP 连接**(P7)—— chromium 二进制不能进 asar

---

## Next Action

运行 `$gsd-discuss-phase 1` 进入 Phase 1 的上下文澄清,或 `$gsd-plan-phase 1` 直接规划。

---
*State initialized: 2026-07-09*
