# Element UI to Element Plus Migration

## Package Change

**Before:**
```json
"element-ui": "^2.15.x"
```
```typescript
import ElementUI from 'element-ui';
import 'element-ui/lib/theme-chalk/index.css';
Vue.use(ElementUI);
```

**After:**
```json
"element-plus": "^2.x"
```
```typescript
import ElementPlus from 'element-plus';
import 'element-plus/dist/index.css';
// In main.ts: app.use(ElementPlus)
```

---

## Icon System (BREAKING)

**Vue2 Element UI:**
```html
<i class="el-icon-edit"></i>
<i class="el-icon-delete"></i>
<el-button icon="el-icon-search">Search</el-button>
```

**Vue3 Element Plus:**
```html
<script setup>
import { Edit, Delete, Search } from '@element-plus/icons-vue';
</script>
<template>
  <el-icon><Edit /></el-icon>
  <el-icon><Delete /></el-icon>
  <el-button :icon="Search">Search</el-button>
</template>
```

**Icon migration mapping** (common ones):
| el-icon-* class | Element Plus import |
|----------------|-------------------|
| el-icon-edit | Edit |
| el-icon-delete | Delete |
| el-icon-search | Search |
| el-icon-plus | Plus |
| el-icon-close | Close |
| el-icon-check | Check |
| el-icon-arrow-down | ArrowDown |
| el-icon-arrow-up | ArrowUp |
| el-icon-arrow-left | ArrowLeft |
| el-icon-arrow-right | ArrowRight |
| el-icon-refresh | Refresh |
| el-icon-loading | Loading |
| el-icon-upload | Upload |
| el-icon-download | Download |
| el-icon-setting | Setting |
| el-icon-user | User |
| el-icon-info | Info |
| el-icon-warning | Warning |
| el-icon-error | CircleClose |
| el-icon-success | CircleCheck |
| el-icon-time | Clock |
| el-icon-date | Calendar |
| el-icon-menu | Menu |
| el-icon-s-tools | Tools |
| el-icon-s-data | DataAnalysis |
| el-icon-s-home | HomeFilled |

For a complete mapping, search the project for ALL `el-icon-` occurrences before starting migration.

---

## Broken/Changed Components

### el-tag

`hit` prop removed, `closable` behavior changed.

**Before:**
```html
<el-tag :hit="true" closable @close="handleClose">Tag</el-tag>
```

**After:**
```html
<el-tag :disable-transitions="false" closable @close="handleClose">Tag</el-tag>
```

### el-submenu → el-sub-menu

**Before:**
```html
<el-menu>
  <el-submenu index="1">
    <template #title>Group</template>
    <el-menu-item index="1-1">Item</el-menu-item>
  </el-submenu>
</el-menu>
```

**After:**
```html
<el-menu>
  <el-sub-menu index="1">
    <template #title>Group</template>
    <el-menu-item index="1-1">Item</el-menu-item>
  </el-sub-menu>
</el-menu>
```

### el-dropdown-item → el-dropdown-item (unchanged name, changed API)

`command` becomes the click handler directly:

**Before:**
```html
<el-dropdown @command="handleCommand">
  <el-dropdown-item command="edit">Edit</el-dropdown-item>
</el-dropdown>
```

**After:**
```html
<el-dropdown>
  <el-dropdown-item @click="handleCommand('edit')">Edit</el-dropdown-item>
</el-dropdown>
```

### el-form-item label-width

The `label-width` prop on individual `el-form-item` still works but the behavior around `auto` may differ.

### el-table

Column `slot` → column `#default` or `v-slot`:

**Before:**
```html
<el-table-column label="Name">
  <template slot-scope="{ row }">
    <span>{{ row.name }}</span>
  </template>
</el-table-column>
```

**After:**
```html
<el-table-column label="Name">
  <template #default="{ row }">
    <span>{{ row.name }}</span>
  </template>
</el-table-column>
```

Any `slot="header"` → `#header`, `slot-scope` → `v-slot` or `#default`.

### el-input size

Size values changed:
| Old | New |
|-----|-----|
| medium | default (removed) |
| small | small |
| mini | removed (use small) |

Check all `size="medium"` usages — they will fail silently.

### el-dialog

`visible` prop changed to `modelValue` (v-model):

**Before:**
```html
<el-dialog :visible.sync="dialogVisible" title="Dialog">
```

**After:**
```html
<el-dialog v-model="dialogVisible" title="Dialog">
```

### el-button type="text" → link

**Before:**
```html
<el-button type="text">Click</el-button>
```

**After:**
```html
<el-button link>Click</el-button>
```

### el-popover / el-tooltip

`v-model` for visibility is now `visible` slot prop:

**Before:**
```html
<el-popover v-model="visible">
```

**After:**
```html
<el-popover :visible="visible" @update:visible="visible = $event">
```

### el-pagination

`layout` values might differ. Check `total`, `page-size` defaults. Some `layout` strings like `"total, sizes, prev, pager, next"` remain compatible but test each.

### el-color-picker

`v-model` format changed — check color string format output.

### el-date-picker

`picker-options` prop removed in favor of individual props. `disabledDate` must be set as a direct prop:

**Before:**
```html
<el-date-picker :picker-options="{ disabledDate: fn }" />
```

**After:**
```html
<el-date-picker :disabled-date="fn" />
```

---

## Common Pitfalls

### 1. Silent import failures
Element Plus uses ES modules. If a component import fails silently, check:
```typescript
// DO NOT import like this (may tree-shake incorrectly):
import { ElButton } from 'element-plus';
// Instead use full import in main.ts or use unplugin-vue-components
```

### 2. CSS class name changes
Some CSS class names changed. `el-*` prefixes remain but some BEM modifiers differ. If a custom style stops working, inspect the rendered DOM for new class names.

### 3. el-form validate callback
Element Plus `validate()` returns a Promise. Callback style still works but Promise style is preferred:
```typescript
// Vue3
await formRef.value.validate();
// instead of
formRef.value.validate((valid) => { ... });
```

### 4. el-message / el-notification / el-message-box
Global methods change:
```typescript
// Vue2
this.$message.success('Done');
this.$confirm('Sure?').then(() => {});
this.$notify({ title: 'Success', message: 'Done' });

// Vue3
import { ElMessage, ElMessageBox, ElNotification } from 'element-plus';
ElMessage.success('Done');
ElMessageBox.confirm('Sure?').then(() => {});
ElNotification({ title: 'Success', message: 'Done' });
```

Search ALL `this.$message`, `this.$notify`, `this.$confirm`, `this.$alert`, `this.$prompt`, `this.$msgbox` usages and replace with imported functions.

### 5. el-select filterable
The `filterable` prop's filter-method behavior may differ. Test each select with search functionality.
