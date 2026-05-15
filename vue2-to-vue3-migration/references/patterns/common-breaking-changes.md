# Common Breaking Changes (Vue2 → Vue3)

Changes that affect ANY component regardless of decorator usage.

## 1. v-model (BREAKING)

**Before (Vue2):**
```html
<ChildComponent v-model="value" />
<!-- equals: -->
<ChildComponent :value="value" @input="value = $event" />
```

**After (Vue3):**
```html
<ChildComponent v-model="value" />
<!-- equals: -->
<ChildComponent :modelValue="value" @update:modelValue="value = $event" />
```

**Named v-model (Vue3 only):**
```html
<ChildComponent v-model:title="title" v-model:visible="visible" />
```

**Migration action**: Search for `$emit('input'` and `prop: 'value'` in all child components. Replace with `$emit('update:modelValue'` (emit) and `modelValue` (prop).

---

## 2. Filters (REMOVED)

**Before (Vue2):**
```html
{{ price | currency }}
{{ date | formatDate('YYYY-MM-DD') }}
```

**After (Vue3):**
```html
{{ formatCurrency(price) }}
{{ formatDate(date, 'YYYY-MM-DD') }}
```

**Migration action**: Search for `|` in templates:
```bash
grep -rn '|[[:space:]]*[a-zA-Z]' --include="*.vue" src/
```
For each filter used, find its definition (usually in `filters/` directory), convert to a plain function or computed property, and import it where needed.

If a filter was registered globally (`Vue.filter('currency', ...)`), convert to a global property (`app.config.globalProperties.$filters = { currency }`) OR convert to imported functions.

---

## 3. Event Bus (REMOVED)

**Before (Vue2):**
```typescript
// event-bus.ts
import Vue from 'vue';
export const EventBus = new Vue();

// Usage:
EventBus.$on('data-updated', this.handleUpdate);
EventBus.$emit('data-updated', data);
EventBus.$off('data-updated', this.handleUpdate);
```

**After (Vue3) — Option A: mitt:**
```bash
npm install mitt
```
```typescript
// event-bus.ts
import mitt from 'mitt';
type Events = { 'data-updated': Data; [key: string]: any };
export const eventBus = mitt<Events>();

// Usage:
eventBus.on('data-updated', handleUpdate);
eventBus.emit('data-updated', data);
eventBus.off('data-updated', handleUpdate);
```

**After (Vue3) — Option B: Pinia store + watch (preferred):**
Move event-based state to a Pinia store with a `watch` in the consumer.

---

## 4. Transition Class Name Changes

| Vue2 | Vue3 |
|------|------|
| `v-enter` | `v-enter-from` |
| `v-leave` | `v-leave-from` |

If using custom transition classes in CSS:
```css
/* Before */
.fade-enter { opacity: 0; }
.fade-enter-active { transition: opacity 0.3s; }

/* After */
.fade-enter-from { opacity: 0; }
.fade-enter-active { transition: opacity 0.3s; }
```

Search: `-enter {` and `-leave {` in CSS/SCSS files.

---

## 5. $listeners Removed (merged into $attrs)

**Before (Vue2):**
```html
<!-- Passing through all listeners to child -->
<ChildComponent v-on="$listeners" v-bind="$attrs" />
```

**After (Vue3):**
```html
<!-- $attrs now includes both attributes AND listeners -->
<ChildComponent v-bind="$attrs" />
```

`$listeners` no longer exists. Everything is in `$attrs`.

---

## 6. v-if / v-for Priority (SWAPPED)

**Before (Vue2)**: `v-for` has higher priority than `v-if` on the same element.
**After (Vue3)**: `v-if` has higher priority.

If they were used on the same element (bad practice but common):
```html
<!-- Vue2: each item checked individually -->
<div v-for="item in items" v-if="item.visible" :key="item.id">

<!-- Vue3: v-if runs first and items doesn't exist yet → breaks -->
<!-- Fix: use computed to filter, or use <template> wrapper -->
<template v-for="item in items" :key="item.id">
  <div v-if="item.visible">
</template>
```

Search: `v-for.*v-if` or `v-if.*v-for` on the same element.

---

## 7. key Attribute on `<template v-for>`

**Before (Vue2)**: `key` goes on the child element.
**After (Vue3)**: `key` goes on `<template>`:

```html
<!-- Vue3 -->
<template v-for="item in items" :key="item.id">
  <div>{{ item.name }}</div>
</template>
```

---

## 8. Functional Components (CHANGED)

**Before (Vue2):**
```html
<template functional>
  <div>{{ props.title }}</div>
</template>
```

**After (Vue3):** Functional components are just plain functions (no template). If a functional component has no logic, convert to a normal component.

---

## 9. async Component Syntax

**Before (Vue2):**
```typescript
const AsyncComp = () => import('./Comp.vue');
// OR
const AsyncComp = () => ({
  component: import('./Comp.vue'),
  loading: LoadingComp,
  delay: 200,
});
```

**After (Vue3):**
```typescript
import { defineAsyncComponent } from 'vue';
const AsyncComp = defineAsyncComponent(() => import('./Comp.vue'));
// OR with options:
const AsyncComp = defineAsyncComponent({
  loader: () => import('./Comp.vue'),
  loadingComponent: LoadingComp,
  delay: 200,
});
```

---

## 10. main.ts Bootstrap

**Before:**
```typescript
import Vue from 'vue';
import App from './App.vue';
import router from './router';
import store from './store';
import ElementUI from 'element-ui';
import 'element-ui/lib/theme-chalk/index.css';

Vue.use(ElementUI);

new Vue({
  router,
  store,
  render: (h) => h(App),
}).$mount('#app');
```

**After:**
```typescript
import { createApp } from 'vue';
import { createPinia } from 'pinia';
import App from './App.vue';
import router from './router';
import ElementPlus from 'element-plus';
import 'element-plus/dist/index.css';

const app = createApp(App);
const pinia = createPinia();

app.use(pinia);
app.use(router);
app.use(ElementPlus);
app.mount('#app');
```

**Order matters**: Pinia must be installed BEFORE router if router guards use stores.

---

## 11. v-bind Merge Behavior (CHANGED)

**Before (Vue2)**: If an element has both a bound attribute and an individual binding, the individual wins.
**After (Vue3)**: Declaration order wins (last binding wins).

```html
<!-- Vue2: id="bar" -->
<!-- Vue3: id="foo" -->
<div v-bind="{ id: 'foo' }" id="bar">
```

This rarely matters but can break if `v-bind="object"` is used with individual bindings.

---

## 12. $children Removed

`this.$children` no longer exists. If used to access child component instances, refactor to use template refs:
```typescript
const childRef = ref<InstanceType<typeof ChildComp>>();
// access: childRef.value?.someMethod()
```

---

## 13. render() Function API (CHANGED)

**Before (Vue2):**
```typescript
render(h) {
  return h('div', { attrs: { id: 'foo' } }, [h('span', 'hello')]);
}
```

**After (Vue3):**
```typescript
import { h } from 'vue';
// h is imported globally, not passed as argument
render() {
  return h('div', { id: 'foo' }, [h('span', 'hello')]);
  // Note: flat props, no 'attrs' wrapper for id
}
```

---

## Verification Script

After migration, run this to catch remaining Vue2-only patterns:

```bash
# Check for Vue2-only syntax
echo "=== Filters ==="
grep -rn '|[[:space:]]*[a-zA-Z]' --include="*.vue" src/ | grep -v '||' | grep -v '//'

echo "=== process.env ==="
grep -rn 'process\.env\.' --include="*.ts" --include="*.vue" --include="*.js" src/

echo "=== require() ==="
grep -rn 'require(' --include="*.ts" --include="*.vue" src/ | grep -v 'node_modules'

echo "=== \$listeners ==="
grep -rn '\$listeners' --include="*.vue" --include="*.ts" src/

echo "=== \$children ==="
grep -rn '\$children' --include="*.vue" --include="*.ts" src/

echo "=== Event bus patterns ==="
grep -rn '\$on\b\|\$off\b\|\$once\b\|\$emit\b' --include="*.vue" --include="*.ts" src/

echo "=== Transition classes ==="
grep -rn '\-enter\b\|\-leave\b' --include="*.scss" --include="*.css" src/
```
