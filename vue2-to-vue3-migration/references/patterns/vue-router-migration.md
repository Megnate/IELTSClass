# Vue Router 3 → 4 Migration

## Package Change

**Before:**
```json
"vue-router": "^3.x"
```

**After:**
```json
"vue-router": "^4.x"
```

---

## Router Creation

**Before (router/index.ts):**
```typescript
import Vue from 'vue';
import Router from 'vue-router';
Vue.use(Router);

const router = new Router({
  mode: 'history',
  base: process.env.BASE_URL,
  routes: [...],
});

export default router;
```

**After (router/index.ts):**
```typescript
import { createRouter, createWebHistory } from 'vue-router';

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [...],
});

export default router;
```

---

## Route Definitions

**Before:**
```typescript
const routes = [
  {
    path: '/job',
    name: 'JobList',
    component: () => import('@/views/job/JobList.vue'),
    meta: { requiresAuth: true },
  },
  {
    path: '/job/:id',
    name: 'JobDetail',
    component: () => import('@/views/job/JobDetail.vue'),
    props: true,
    children: [
      {
        path: 'history',
        component: () => import('@/views/job/JobHistory.vue'),
      },
    ],
  },
];
```

Route definitions remain largely the same. Key changes:

### Catch-all route (404)

**Before:**
```typescript
{ path: '*', component: NotFound }
```

**After:**
```typescript
{ path: '/:pathMatch(.*)*', name: 'NotFound', component: NotFound }
```

---

## Navigation Guards

**Before:**
```typescript
// In-component guard
@Component
export default class JobDetail extends Vue {
  beforeRouteEnter(to: Route, from: Route, next: (vm?: any) => void) {
    // Accessing `this` is not possible here in Vue2 either
    next((vm) => { vm.fetchData(); });
  }

  beforeRouteLeave(to: Route, from: Route, next: () => void) {
    if (this.hasUnsavedChanges) {
      if (confirm('Leave?')) next();
      else next(false);
    } else {
      next();
    }
  }
}
```

**After:**
```typescript
// onBeforeRouteLeave is imported, not a class method
import { onBeforeRouteLeave, onBeforeRouteUpdate } from 'vue-router';

onBeforeRouteLeave((to, from) => {
  if (hasUnsavedChanges.value) {
    const answer = window.confirm('Leave?');
    if (!answer) return false;
  }
});
```

**Note**: `beforeRouteEnter` has no direct Composition API equivalent (it never had `this` access anyway). Use it with a callback or restructure to use `onMounted` + route params.

---

## Router in Components

**Before (class component):**
```typescript
import { Vue } from 'vue-property-decorator';

@Component
export default class JobList extends Vue {
  get jobId() { return this.$route.params.id; }
  get currentPath() { return this.$route.path; }

  navigateToDetail(id: string) {
    this.$router.push({ name: 'JobDetail', params: { id } });
  }

  goBack() {
    this.$router.back();
  }
}
```

**After:**
```typescript
import { useRoute, useRouter } from 'vue-router';

const route = useRoute();
const router = useRouter();

const jobId = computed(() => route.params.id as string);
const currentPath = computed(() => route.path);

function navigateToDetail(id: string) {
  router.push({ name: 'JobDetail', params: { id } });
}

function goBack() {
  router.back();
}
```

---

## Template $route / $router

**Before:**
```html
<router-link :to="{ name: 'JobDetail', params: { id: item.id } }">
  {{ item.name }}
</router-link>
<span>{{ $route.params.id }}</span>
```

**After:**
```html
<!-- router-link is unchanged -->
<router-link :to="{ name: 'JobDetail', params: { id: item.id } }">
  {{ item.name }}
</router-link>
<!-- Use data from setup, not $route directly -->
<span>{{ route.params.id }}</span>
```

`<router-link>` and `<router-view>` remain unchanged.

---

## Key Behavior Changes

### 1. router.push().catch
In Vue Router 4, `router.push()` returns a Promise that rejects on navigation failure (e.g., navigating to the same route, or a guard returning false). Vue Router 3 silently suppressed these.

**Fix**: Add `.catch(() => {})` to `router.push()` calls if unhandled rejection warnings appear:
```typescript
router.push({ name: 'Home' }).catch(() => {});
```
OR wrap all `push`/`replace` calls in a helper.

### 2. params removed on path mismatch
In VR3, if `name` and `params` don't match, it falls back to `path`. In VR4, missing params are removed and can cause navigation errors. Always ensure `params` match the named route definition.

### 3. router.addRoute parent removal
`router.addRoute(parentName, route)` replaces the old `router.addRoutes([...])` + `router.addRoute(parentName, route)` pattern for adding child routes to an existing route.

### 4. router.onReady removed
`router.onReady()` is removed. Use `router.isReady()` which returns a Promise:
```typescript
await router.isReady();
```

---

## Common Pitfalls

### 1. $route params type
In Vue2 with TypeScript, `this.$route.params.id` was `string | undefined`. In Vue3 with `useRoute()`, it's `string | string[]`. Cast to string explicitly:
```typescript
const id = computed(() => route.params.id as string);
```

### 2. Route name clashes
Vue Router 4 is stricter about duplicate route names. If the project has duplicate route names (common in large codebases), they will cause warnings or errors. Check for duplicates.

### 3. router-link active class
The default active class is still `router-link-active` but the scoping behavior may differ. Check navigation highlighting after migration.

### 4. Scroll behavior
If a custom `scrollBehavior` function exists, it needs to return `el.scrollTo` (VR4) instead of mutating `savedPosition` (VR3). The function signature is unchanged but the return value handling is stricter.
