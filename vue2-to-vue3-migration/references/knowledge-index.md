# Migration Knowledge Index

This file tracks known migration patterns, past errors, and solutions discovered during real migrations. Updated after each module migration.

## Usage

Before starting a module migration, use a sub-agent to search this index:
```
Goal: Search the vue2-to-vue3-migration knowledge base for patterns, errors, and lessons relevant to migrating [MODULE NAME].
Check: knowledge-index.md for any module-specific notes, decorator-to-script-setup.md for component patterns, vuex-to-pinia.md for store patterns, element-ui-to-element-plus.md for UI patterns, and common-breaking-changes.md for global issues.
Report: which patterns apply, which past errors to avoid, and any module-specific quirks.
```

---

## Completed Migrations

<!-- After each module is migrated, add an entry here with: module name, date, files changed, key lessons, new patterns discovered -->

### Template Entry
```
### [MODULE_NAME] - [YYYY-MM-DD]
- Files migrated: N .vue, N .ts
- Key patterns used: decorator-to-script-setup, vuex-to-pinia, element-ui-to-element-plus
- New lessons: [2-3 sentence summary]
- New patterns: [if any new patterns were added to reference files]
- Report: docs/migration-reports/[MODULE_NAME]-[YYYY-MM-DD].html
```

---

## Known Module-Specific Quirks

<!-- Document quirks specific to each module that deviate from standard patterns -->

---

## Error Catalog

Common errors encountered during migration, organized by symptom.

### TypeScript Errors

| Error | Cause | Fix | First Seen |
|-------|-------|-----|------------|
| `Property 'xxx' does not exist on type` | Forgot `.value` on ref | Add `.value` | - |
| `Cannot find module '@/...' or its corresponding type declarations` | Missing path alias in tsconfig | Add `"paths": {"@/*": ["./src/*"]}` to tsconfig | - |
| `Argument of type 'string' is not assignable to parameter of type 'Ref<string>'` | Passing plain value where ref expected | Wrap with `ref()` or accept plain value in function | - |

### Build Errors

| Error | Cause | Fix | First Seen |
|-------|-------|-----|------------|
| `require is not defined` | `require()` in browser code | Convert to `import` or `new URL(..., import.meta.url)` | - |
| `process is not defined` | `process.env.*` in browser code | Convert to `import.meta.env.*` | - |

### Runtime Errors

| Error | Cause | Fix | First Seen |
|-------|-------|-----|------------|
| `Cannot read properties of undefined (reading 'xxx')` | Destructured store without `storeToRefs` | Use `storeToRefs(store)` | - |
| `v-model` not updating parent | Child emits `input` instead of `update:modelValue` | Change emit name | - |
| Element UI component not rendering | Missing Element Plus import or name mismatch | Check element-ui-to-element-plus.md mapping | - |
| Page blank after router navigation | `router.push()` rejected silently | Add `.catch(() => {})` | - |

### Visual Regression

| Issue | Cause | Fix | First Seen |
|-------|-------|-----|------------|
| El-tag missing background | `hit` prop removed | Remove `:hit="true"` | - |
| El-button type="text" looks wrong | `type="text"` removed | Change to `link` | - |
| Icons not showing | `el-icon-*` class no longer works | Use `@element-plus/icons-vue` components | - |

---

## How to Update This File

After each module migration, if you discover:

1. A new error → add to Error Catalog with the 'First Seen' module name
2. A new pattern → add to the appropriate `references/patterns/*.md` file AND note it in the module's entry above
3. A module-specific quirk → add to "Known Module-Specific Quirks"
4. A completed migration → add to "Completed Migrations"

Use `skill_manage(action='patch', name='vue2-to-vue3-migration', file_path='references/knowledge-index.md', ...)` to update.
