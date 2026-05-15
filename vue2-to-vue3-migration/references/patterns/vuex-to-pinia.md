# Vuex to Pinia Migration

Converting Vuex modules (with namespaces) to Pinia stores.

## Before/After Cheat Sheet

### Store Module Structure

**Vuex (before):**
```
store/
  modules/
    job/           # namespaced: true
      index.ts     # re-exports
      state.ts
      getters.ts
      mutations.ts
      actions.ts
      types.ts
```

**Pinia (after):**
```
stores/
  job.ts           # single file per store
  /job/            # OR directory for large stores
    index.ts
    /composables   # extracted logic
```

---

### State

**Vuex:**
```typescript
// store/modules/job/state.ts
export interface JobState {
  list: Job[];
  current: Job | null;
  loading: boolean;
  filters: JobFilters;
}

export const state: JobState = {
  list: [],
  current: null,
  loading: false,
  filters: { status: '', type: '' },
};
```

**Pinia:**
```typescript
// stores/job.ts
import { defineStore } from 'pinia';
import { ref, reactive, computed } from 'vue';

interface JobState {
  list: Job[];
  current: Job | null;
  loading: boolean;
  filters: JobFilters;
}

export const useJobStore = defineStore('job', () => {
  // Use ref() for primitives and arrays
  const list = ref<Job[]>([]);
  const current = ref<Job | null>(null);
  const loading = ref(false);
  const filters = reactive<JobFilters>({ status: '', type: '' });

  // OR use a single reactive object (Setup Store style):
  // const state = reactive<JobState>({
  //   list: [],
  //   current: null,
  //   loading: false,
  //   filters: { status: '', type: '' },
  // });
});
```

**Key decision**: Setup Store (composition API style with `ref`) vs Options Store (`state: () => ({})`). Use Setup Store for consistency with the rest of the Composition API codebase.

---

### Getters

**Vuex:**
```typescript
// store/modules/job/getters.ts
export const getters = {
  activeJobs: (state: JobState) => state.list.filter(j => j.active),
  jobById: (state: JobState) => (id: string) => state.list.find(j => j.id === id),
  hasFilters: (state: JobState) => state.filters.status !== '' || state.filters.type !== '',
};
```

**Pinia:**
```typescript
// Inside defineStore setup function
const activeJobs = computed(() => list.value.filter(j => j.active));
const jobById = computed(() => (id: string) => list.value.find(j => j.id === id));
const hasFilters = computed(() => filters.status !== '' || filters.type !== '');
```

**Important**: Pinia getters are just `computed()` calls. No separate section needed.

---

### Mutations → Actions (merged)

**Vuex:**
```typescript
// store/modules/job/mutations.ts
export const mutations = {
  SET_LIST(state: JobState, list: Job[]) {
    state.list = list;
  },
  SET_CURRENT(state: JobState, job: Job | null) {
    state.current = job;
  },
  SET_LOADING(state: JobState, loading: boolean) {
    state.loading = loading;
  },
  ADD_JOB(state: JobState, job: Job) {
    state.list.push(job);
  },
  UPDATE_JOB(state: JobState, updated: Job) {
    const idx = state.list.findIndex(j => j.id === updated.id);
    if (idx >= 0) state.list.splice(idx, 1, updated);
  },
};
```

**Pinia**: The concept of "mutations" does not exist. All state changes are done directly in actions (or in the component, though that's discouraged). Convert mutations to simple functions:

```typescript
// Inside defineStore setup function
function setList(newList: Job[]) {
  list.value = newList;
}

function setCurrent(job: Job | null) {
  current.value = job;
}

function setLoading(val: boolean) {
  loading.value = val;
}

function addJob(job: Job) {
  list.value.push(job);
}

function updateJob(updated: Job) {
  const idx = list.value.findIndex(j => j.id === updated.id);
  if (idx >= 0) list.value.splice(idx, 1, updated);
}
```

---

### Actions

**Vuex:**
```typescript
// store/modules/job/actions.ts
import { ActionContext } from 'vuex';
import { RootState } from '@/store/types';

export const actions = {
  async fetchJobs({ commit, state, rootState }: ActionContext<JobState, RootState>) {
    commit('SET_LOADING', true);
    try {
      const list = await jobApi.getList(state.filters);
      commit('SET_LIST', list);
      return list;
    } finally {
      commit('SET_LOADING', false);
    }
  },

  async createJob({ commit, dispatch }, payload: CreateJobPayload) {
    const job = await jobApi.create(payload);
    commit('ADD_JOB', job);
    dispatch('notification/success', 'Job created', { root: true });
  },
};
```

**Pinia:**
```typescript
// Inside defineStore setup function
async function fetchJobs() {
  loading.value = true;
  try {
    const result = await jobApi.getList(filters);
    list.value = result;
    return result;
  } finally {
    loading.value = false;
  }
}

async function createJob(payload: CreateJobPayload) {
  const job = await jobApi.create(payload);
  list.value.push(job);
  // Cross-store access:
  const notificationStore = useNotificationStore();
  notificationStore.success('Job created');
}
```

**Key changes:**
1. No `commit` — just assign directly to state
2. No `dispatch` for cross-store — import and call the other store directly
3. No `rootState` — import and use the other store
4. `{ root: true }` dispatch → direct store function call

---

### Component Usage

**Vue2 class component:**
```typescript
import { namespace } from 'vuex-class';
const jobModule = namespace('job');

@Component
export default class JobList extends Vue {
  @jobModule.State('list') list!: Job[];
  @jobModule.State('loading') loading!: boolean;
  @jobModule.Getter('activeJobs') activeJobs!: Job[];
  @jobModule.Action('fetchJobs') fetchJobs!: () => Promise<Job[]>;
  @jobModule.Mutation('SET_LOADING') setLoading!: (val: boolean) => void;

  async mounted() {
    await this.fetchJobs();
  }
}
```

**Vue3:**
```typescript
import { useJobStore } from '@/stores/job';
import { storeToRefs } from 'pinia';

const jobStore = useJobStore();

// Destructure state (reactive):
const { list, loading } = storeToRefs(jobStore);

// Actions can be destructured directly (they are functions, not reactive):
const { fetchJobs } = jobStore;
// OR just call: jobStore.fetchJobs()

// Getters:
const { activeJobs } = storeToRefs(jobStore);

onMounted(async () => {
  await fetchJobs();
});
```

**CRITICAL**: Use `storeToRefs()` for state properties, NOT direct destructuring. `const { list } = jobStore` loses reactivity. `const { list } = storeToRefs(jobStore)` preserves it.

---

### Namespaced Modules → Flat Stores

**Vuex (before):**
```typescript
// Accessing another namespaced module
this.$store.dispatch('wafer/fetchWafer', id, { root: true });
this.$store.state.wafer.currentWafer;
this.$store.getters['wafer/activeWafers'];
```

**Pinia (after):**
```typescript
import { useWaferStore } from '@/stores/wafer';
const waferStore = useWaferStore();

waferStore.fetchWafer(id);
waferStore.currentWafer;  // accessing directly
```

No namespaces. Each store is imported and used directly.

---

### $store in Templates

**Vue2:**
```html
<template>
  <div v-if="$store.state.job.loading">Loading...</div>
  <div v-for="job in $store.state.job.list" :key="job.id">{{ job.name }}</div>
</template>
```

**Vue3:**
```html
<script setup lang="ts">
import { useJobStore } from '@/stores/job';
import { storeToRefs } from 'pinia';
const jobStore = useJobStore();
const { list, loading } = storeToRefs(jobStore);
</script>

<template>
  <div v-if="loading">Loading...</div>
  <div v-for="job in list" :key="job.id">{{ job.name }}</div>
</template>
```

NO direct `$store` access in templates. Always provide via setup.

---

## Common Pitfalls

### 1. Forgetting storeToRefs
`const { list } = useJobStore()` — `list` is NOT reactive. Always wrap with `storeToRefs()` for state properties.

### 2. Circular store dependencies
If store A imports store B and store B imports store A, you get a circular dependency. Fix by calling `useStoreB()` inside the action function, not at the top level:

```typescript
// Inside storeA action:
async function doSomething() {
  const storeB = useStoreB();  // lazy import inside function
  storeB.someAction();
}
```

### 3. Using this.$store.getters['module/getter'] in migrated code
Search and replace ALL `this.$store.*` references. In particular:
- `this.$store.state.module.field` → import store, use `storeToRefs`
- `this.$store.getters['module/getter']` → import store, use `storeToRefs` or direct access
- `this.$store.commit('module/MUTATION', payload)` → `store.function(payload)`
- `this.$store.dispatch('module/action', payload)` → `store.action(payload)`

### 4. Vuex plugins
Vuex plugins (like `createPersistedState`, `createLogger`) have Pinia equivalents (`pinia-plugin-persistedstate`). Migrate these in store/index.ts → main.ts Pinia setup.

### 5. mapState / mapGetters / mapActions / mapMutations in Options API components
If any non-class components use `mapState`, `mapGetters` etc., they must be manually converted. Pinia has `mapState` and `mapActions` helpers but they are deprecated — convert to `storeToRefs` + direct calls.
