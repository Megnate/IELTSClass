---
name: vue2-to-vue3-migration
description: "Use when migrating a Vue2 project (Vue CLI + vue-property-decorator + Webpack + Vuex + Element UI) to Vue3 (Vite + Composition API + Pinia + Element Plus). Module-by-module workflow with automated code analysis, pattern-matching against known migration solutions, Playwright visual regression verification, and HTML report generation. Triggers: upgrade, migrate, vue3, 'vue2 to vue3', 'migration plan', 'element-ui to element-plus'."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [vue, migration, vue3, vite, pinia, element-plus, playwright, code-upgrade]
    related_skills: [systematic-debugging, test-driven-development, writing-plans, subagent-driven-development]
---

# Vue2 to Vue3 Migration

Migrate a large multi-module Vue2 codebase to Vue3, module by module, with zero functional regressions.

## Overview

This skill guides the migration of a project from:

| Layer | Current | Target |
|-------|---------|--------|
| Framework | Vue 2.x | Vue 3.x |
| Build | Vue CLI + Webpack | Vite |
| State | Vuex | Pinia |
| UI Library | Element UI | Element Plus |
| Class Syntax | vue-property-decorator | Composition API (`<script setup>`) |
| Language | TypeScript | TypeScript |

The project has 700K+ lines across multiple modules: Home, Job, Wafer Queue, Recipe, Sequence, Offset, User Permission, Wafer History, Chamber History, and others. Each module is migrated independently by different developers.

**Core principle**: Functionality correctness above syntax elegance. Decorator-based class components can coexist with Composition API — prioritize zero bugs over style purity.

## When to Use

### Must Use
- Any phrase: "upgrade to Vue3", "migrate to Vue3", "vue2 to vue3"
- Upgrading a single module/directory from the Vue2 project
- Fixing a regression introduced by a prior migration step
- Generating a migration report for a completed module

### Skip
- Pure bug fixes unrelated to the migration
- New feature development (not migration)
- Backend/API changes

## Prerequisites

Before starting, verify the environment:

```bash
node --version  # should be >= 18
python3 --version || python --version  # for analysis scripts
npx playwright --version  # for visual verification
```

## Migration Workflow

Every module migration follows this 5-phase process. Do NOT skip phases.

### Phase 0: Module Scoping

First, identify what you're migrating. The user may say "migrate the Job module" or "upgrade the Wafer Queue pages."

**Step 0.1: Locate the module**

```bash
# Find all Vue files related to the module
find /path/to/project/src -type f \( -name "*.vue" -o -name "*.ts" -o -name "*.js" \) | xargs grep -il "<module-keyword>" | head -80
```

**Step 0.2: Count and categorize files**

Run this to understand the scope. Use a sub-agent if the output is large:

```python
from hermes_tools import terminal
import json

# Count files by type in the module directory
result = terminal(f"find /path/to/module -type f | sed 's/.*\\.//' | sort | uniq -c | sort -rn")
print(result["output"])
```

**Step 0.3: Check existing Playwright tests**

Search for existing test screenshots or Playwright tests for the module:

```bash
find /path/to/project -type d -name "playwright" -o -name "tests" -o -name "e2e" -o -name "screenshots" | head -20
find /path/to/project -type f -name "*.spec.ts" -o -name "*.spec.js" -o -name "*.test.ts" | head -20
find /path/to/project -type f \( -name "*.png" -o -name "*.jpg" \) -path "*screen*" | head -20
```

Record whether Playwright tests exist. If they don't, note that manual testing or new Playwright baselines will be needed.

**Step 0.4: Produce scoping summary**

Output a scoping report with:
- Module name and path
- File counts: .vue components, .ts/.js files, store modules, mixins (if any)
- Playwright test status: EXISTING / NONE
- Estimated complexity: LOW (< 20 files), MEDIUM (20-50 files), HIGH (> 50 files)

---

### Phase 1: Knowledge Lookup (DO THIS FIRST)

Before touching any code, search the knowledge base for solved patterns. This avoids repeating mistakes.

**Step 1.1: Search for similar module migrations**

Use `delegate_task` to search the skill's reference files for patterns relevant to the module being migrated:

```text
Goal: Search the Vue2-to-Vue3 migration knowledge base for patterns relevant to [MODULE NAME] migration.
Search for: decorator patterns, Vuex store patterns, Element UI components used, mixin patterns, and any past errors logged for similar modules.
Report back: (1) relevant pattern files found, (2) specific examples that apply to this module, (3) known pitfalls to avoid.
```

**Step 1.2: Categorize the migration work**

Based on the file analysis (Phase 0) and knowledge lookup (Phase 1), categorize each file:

| Migration Type | Description | Reference File |
|---------------|-------------|----------------|
| CLASS_COMPONENT | @Component decorator → `<script setup>` | `references/patterns/decorator-to-script-setup.md` |
| VUEX_STORE | Vuex module → Pinia store | `references/patterns/vuex-to-pinia.md` |
| ELEMENT_UI | Element UI → Element Plus API changes | `references/patterns/element-ui-to-element-plus.md` |
| MIXIN | Vue mixin → Composable (composables/) | `references/patterns/mixins-to-composables.md` |
| ROUTER | vue-router 3 → 4 | `references/patterns/vue-router-migration.md` |
| BUILD_CONFIG | Webpack → Vite | `references/patterns/webpack-to-vite.md` |
| FILTERS | Vue filters → computed/functions | `references/patterns/common-breaking-changes.md` |
| EVENTBUS | $on/$off → mitt or composable | `references/patterns/common-breaking-changes.md` |

**Step 1.3: Load relevant pattern files**

For each category that applies, load the reference:

```
skill_view(name='vue2-to-vue3-migration', file_path='references/patterns/decorator-to-script-setup.md')
```

Read the pattern file BEFORE starting migration of that file type.

---

### Phase 2: Execute Migration

Migrate files in this order (dependencies-first):

1. Build configuration (vite.config.ts, tsconfig, package.json)
2. Store modules (Vuex → Pinia)
3. Composables (from mixins)
4. Router (Vue Router 3 → 4)
5. Shared/business logic (.ts files — usually minimal changes)
6. UI components (Element UI → Element Plus)
7. Page/View components (.vue files, bottom-up: leaf components first)
8. Entry files (main.ts, App.vue)

**For each file being migrated:**

a. Read the current file fully
b. Load the relevant pattern reference from the knowledge base
c. Apply the migration, referencing the pattern for exact before/after mappings
d. After writing, immediately verify there are no syntax issues:

```bash
# For .vue files — check the script block parses
npx vue-tsc --noEmit path/to/file.vue 2>&1 | head -30
```

**Migration rules (CRITICAL):**

1. NEVER change business logic. Only change framework syntax.
2. If a decorator pattern has no clean Composition API equivalent, leave it with a `// TODO: migrate` comment and record it.
3. Preserve ALL existing comments.
4. Do NOT reformat unchanged code.
5. If Element Plus removed a component, use the documented replacement. If the replacement requires different props, adapt carefully.

---

### Phase 3: Verification

**Step 3.1: TypeScript check**

```bash
npx vue-tsc --noEmit 2>&1 | grep -i "error" | head -50
```

Address every error. If an error is a false positive from a library type mismatch, document it.

**Step 3.2: Build check**

```bash
npx vite build 2>&1 | tail -30
```

The build must succeed with zero errors.

**Step 3.3: Playwright visual regression**

If Playwright tests exist for this module:

```bash
npx playwright test --grep "[MODULE_NAME]" 2>&1
```

If no Playwright tests exist, create baseline screenshots for the module's key pages:

```bash
# Start the dev server first (background)
# Then capture screenshots
npx playwright test --config=playwright.config.ts --grep "[MODULE_NAME]"
```

Document which pages were screenshot-tested and whether any visual diffs were found.

**Step 3.4: Dev server smoke test**

```bash
npx vite --port 5173
# Check: does the dev server start? Are there runtime errors in the browser console?
# Check: can you navigate to the module's pages? Do they render?
```

---

### Phase 4: Report & Knowledge Capture

**Step 4.1: Generate HTML migration report**

Always produce an HTML report at the end of each module migration. Use the template at `references/templates/migration-report.html`.

The report MUST include these sections:
- Module name and migration date
- File migration summary (count by type, how many files changed)
- Pattern summary (which patterns were applied, from which reference files)
- New lessons learned (any errors encountered and how they were fixed)
- Playwright verification results (screenshots, diffs, or "no existing tests")
- Build & TypeScript check results
- Known TODOs or deferred items

Save the report to the project (NOT to the skill directory):

```
/path/to/project/docs/migration-reports/[MODULE_NAME]-[YYYY-MM-DD].html
```

**Step 4.2: Update the knowledge base**

If you discovered a new migration pattern, an unexpected error, or a new Element UI → Element Plus mapping that isn't documented:

1. Add it to the appropriate reference file using `skill_manage(action='patch', name='vue2-to-vue3-migration', file_path='references/patterns/...', ...)`
2. If it's a new category of issue, create a new section in the relevant reference file

Types of knowledge to capture:
- A decorator pattern → Composition API mapping you hadn't seen before
- An Element UI component that behaves differently in Element Plus
- A Vuex pattern that required a non-obvious Pinia translation
- A build error and its fix
- A runtime error that only appeared in Vue3

---

## Common Pitfalls

### 1. v-model breaking change
In Vue2, `v-model` on a component uses `value` prop + `input` event. In Vue3 it uses `modelValue` prop + `update:modelValue` event. This is one of the most common silent breakages.

**Fix**: Search for `$emit('input'` and replace with `$emit('update:modelValue'`. Search for `{ value }` in props and replace with `{ modelValue }`.

### 2. Filters removed in Vue3
Vue3 removed the `filters` feature. Any `{{ value | filterName }}` will silently render nothing.

**Fix**: Replace filters with computed properties or plain functions. Search the codebase with: `grep -rn '|[[:space:]]*[a-zA-Z]' --include="*.vue" path/to/module`

### 3. Event Bus removed
`$on`, `$off`, `$once` are gone. Code using `this.$root.$on(...)` or a global event bus will fail silently.

**Fix**: Use `mitt` (lightweight) or convert to Pinia store + watch.

### 4. Transition class name changes
`v-enter` → `v-enter-from`, `v-leave` → `v-leave-from`. Custom transition classes in CSS will break.

### 5. Element UI → Element Plus: Tag prop removal
Element Plus removed `hit` prop from `el-tag`. Also `closable` → `closable` (same name) but type changed.

### 6. Element UI → Element Plus: icon changes
`el-icon-*` class names changed. Element Plus uses component-based icons: `<el-icon><Edit /></el-icon>` instead of `<i class="el-icon-edit"></i>`.

### 7. @Watch deep option
`@Watch('propName', { deep: true })` works differently in Composition API. Use `watch(() => props.propName, callback, { deep: true })`.

### 8. Do NOT blindly convert decorators
Some decorator patterns (especially complex @Watch with multiple dependencies) are error-prone to convert. If a conversion looks risky, leave the class component syntax (it works in Vue3 with `@vue/compat`) and mark it as deferred.

---

## Verification Checklist

- [ ] Phase 0 complete: module scoped, file counts, Playwright status known
- [ ] Phase 1 complete: knowledge base searched, pattern files loaded
- [ ] Phase 2 complete: all files migrated in dependency order
- [ ] TypeScript check: zero new errors
- [ ] Build check: `vite build` succeeds
- [ ] Playwright: tests run OR baseline screenshots captured
- [ ] Dev server: pages render without runtime errors
- [ ] HTML report saved to `docs/migration-reports/`
- [ ] Knowledge base updated with any new patterns or errors
- [ ] No `TODO: migrate` comments left without explanation in report
