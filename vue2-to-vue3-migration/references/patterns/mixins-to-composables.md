# Mixins to Composables

Converting Vue2 mixins to Vue3 composables (`composables/` directory).

## Conversion Pattern

**Vue2 mixin:**
```typescript
// mixins/loading-mixin.ts
import { Vue, Component } from 'vue-property-decorator';

@Component
export class LoadingMixin extends Vue {
  loading = false;
  errorMessage = '';

  async withLoading<T>(fn: () => Promise<T>): Promise<T> {
    this.loading = true;
    this.errorMessage = '';
    try {
      return await fn();
    } catch (e: any) {
      this.errorMessage = e.message || 'Unknown error';
      throw e;
    } finally {
      this.loading = false;
    }
  }
}

// Used in component:
@Component
export default class JobList extends Mixins(LoadingMixin, PaginationMixin) {
  // ...
}
```

**Vue3 composable:**
```typescript
// composables/useLoading.ts
import { ref } from 'vue';

export function useLoading() {
  const loading = ref(false);
  const errorMessage = ref('');

  async function withLoading<T>(fn: () => Promise<T>): Promise<T> {
    loading.value = true;
    errorMessage.value = '';
    try {
      return await fn();
    } catch (e: any) {
      errorMessage.value = e.message || 'Unknown error';
      throw e;
    } finally {
      loading.value = false;
    }
  }

  return { loading, errorMessage, withLoading };
}

// Used in component:
// <script setup lang="ts">
import { useLoading } from '@/composables/useLoading';
import { usePagination } from '@/composables/usePagination';

const { loading, errorMessage, withLoading } = useLoading();
const { page, pageSize, total } = usePagination();
```

---

## Key Differences

| Aspect | Vue2 Mixin | Vue3 Composable |
|--------|-----------|-----------------|
| Registration | `class X extends Mixins(A, B)` | `const a = useA(); const b = useB()` |
| `this` access | `this.loading = true` | `loading.value = true` |
| Lifecycle merge | Automatic | Each composable calls its own `onMounted` etc. |
| Name conflicts | Silent override (last wins) | Explicit (you control which to use) |
| TypeScript | Requires `Mixins` type hack | Fully typed naturally |

---

## Mixin with Lifecycle Hooks

**Vue2:**
```typescript
@Component
export class AutoRefreshMixin extends Vue {
  private timer: any = null;
  private INTERVAL = 5000;

  mounted() {
    this.startRefresh();
  }

  beforeDestroy() {
    this.stopRefresh();
  }

  startRefresh() {
    this.timer = setInterval(() => this.onRefresh(), this.INTERVAL);
  }

  stopRefresh() {
    if (this.timer) { clearInterval(this.timer); this.timer = null; }
  }

  onRefresh() {
    // override in component
  }
}
```

**Vue3 composable:**
```typescript
import { onMounted, onBeforeUnmount } from 'vue';

export function useAutoRefresh(onRefresh: () => void, interval = 5000) {
  let timer: ReturnType<typeof setInterval> | null = null;

  function startRefresh() {
    timer = setInterval(onRefresh, interval);
  }

  function stopRefresh() {
    if (timer) { clearInterval(timer); timer = null; }
  }

  onMounted(() => startRefresh());
  onBeforeUnmount(() => stopRefresh());

  return { startRefresh, stopRefresh };
}
```

---

## Dealing with `Mixins(A, B, C)`

**Vue2 class:**
```typescript
@Component
export default class MyComponent extends Mixins(LoadingMixin, AuthMixin, FilterMixin) {
  // component code
}
```

**Vue3:**
```typescript
const { loading, withLoading } = useLoading();
const { user, hasPermission } = useAuth();
const { filters, applyFilters } = useFilter();

// If composables need each other, pass them:
const { user } = useAuth();
const { filters, applyFilters } = useFilter(user); // depends on user
```

---

## Common Pitfalls

### 1. Multiple onMounted calls
Vue2: if mixins A and B both had `mounted()`, only the component's own `mounted()` ran (class single-inheritance). In Vue3, if composables A and B both call `onMounted(...)`, BOTH run. This can cause double initialization.

**Fix**: Check each composable for side effects in lifecycle hooks. If a mixin was intentionally overridden, extract that logic.

### 2. Mixin property access via `this`
Vue2 mixins freely access `this.xxx` assuming the component has that property. Vue3 composables take explicit parameters.

**Fix**: For each `this.xxx` in a mixin, determine if it should be:
- A parameter to the composable function
- A value returned by the composable
- A ref created inside the composable

### 3. Mixin that depends on another mixin
Vue2: `Mixins(A, B)` where A's methods call B's methods via `this`.

**Fix**: Make the dependency explicit:
```typescript
const b = useB();
const a = useA(b); // pass b's API to a
```

### 4. Global mixins (`Vue.mixin(...)`)
Global mixins (registered in main.ts) affect every component. Check main.ts for `Vue.mixin({...})` calls. These often add global methods like `this.$formatDate`. Convert to:
- A composable that components import
- A global property via `app.config.globalProperties`
- A provide/inject pattern at the App level
