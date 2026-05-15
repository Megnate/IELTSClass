# Decorator to Script Setup Migration

Converting `vue-property-decorator` class components to Vue3 `<script setup lang="ts">` with Composition API.

## Before/After Cheat Sheet

### @Component → `<script setup lang="ts">`

**Vue2 (before):**
```vue
<script lang="ts">
import { Component, Vue, Prop, Watch, Emit, Ref, Provide, Inject } from 'vue-property-decorator';

@Component({ name: 'MyComponent', components: { ChildComp } })
export default class MyComponent extends Vue {
  // ...
}
</script>
```

**Vue3 (after):**
```vue
<script setup lang="ts">
import { ref, computed, watch, provide, inject, onMounted, onUnmounted } from 'vue';
import ChildComp from './ChildComp.vue';

defineOptions({ name: 'MyComponent' });
// imports are auto-registered as components
</script>
```

**Key difference**: All `import`ed .vue files are automatically available as components in `<script setup>`. No need for `components: {}` registration.

---

### @Prop → defineProps

**Vue2:**
```typescript
import { Component, Vue, Prop } from 'vue-property-decorator';

@Component
export default class MyComponent extends Vue {
  @Prop({ type: String, required: true }) readonly title!: string;
  @Prop({ type: Number, default: 0 }) readonly count!: number;
  @Prop({ type: Boolean, default: false }) readonly visible!: boolean;
  @Prop({ type: Object, default: () => ({}) }) readonly config!: Config;
  @Prop({ type: Array, default: () => [] }) readonly items!: Item[];
}
```

**Vue3:**
```typescript
interface Props {
  title: string;
  count?: number;
  visible?: boolean;
  config?: Config;
  items?: Item[];
}

const props = withDefaults(defineProps<Props>(), {
  count: 0,
  visible: false,
  config: () => ({}),
  items: () => [],
});
```

**WARNING**: `defineProps` with TypeScript interface cannot have both `required` marker and default. Use `withDefaults` for optional props with defaults, and plain `defineProps<Props>()` when all props are required.

**Vue2 pattern: prop with validator**
```typescript
@Prop({ type: String, validator: (v: string) => ['a', 'b'].includes(v) })
readonly mode!: string;
```

**Vue3 pattern:**
```typescript
const props = defineProps<{ mode: string }>();
// Validation in watch or computed — defineProps does not support validators
watch(() => props.mode, (val) => {
  if (!['a', 'b'].includes(val)) {
    console.warn(`Invalid mode: ${val}`);
  }
});
```

---

### @Watch → watch

**Vue2:**
```typescript
import { Watch } from 'vue-property-decorator';

@Watch('title')
onTitleChange(newVal: string, oldVal: string) {
  console.log('title changed', newVal, oldVal);
}

@Watch('title', { deep: true, immediate: true })
onTitleDeep(newVal: string) {
  this.doSomething(newVal);
}

@Watch('items', { deep: true })
onItemsChange(newItems: Item[]) {
  this.processItems(newItems);
}
```

**Vue3:**
```typescript
import { watch } from 'vue';

// Simple watch
watch(() => props.title, (newVal, oldVal) => {
  console.log('title changed', newVal, oldVal);
});

// Deep + immediate
watch(() => props.title, (newVal) => {
  doSomething(newVal);
}, { deep: true, immediate: true });

// Watch ref/reactive directly (deep by default for reactive objects)
watch(items, (newItems) => {
  processItems(newItems);
}, { deep: true });

// Watch multiple sources
watch([() => props.title, () => props.count], ([newTitle, newCount]) => {
  // handle both
});
```

**Common error**: `watch(props.title, ...)` — `props` is a reactive object, but `props.title` is a plain string. Must use getter: `watch(() => props.title, ...)`.

---

### @Emit → defineEmits

**Vue2:**
```typescript
import { Emit } from 'vue-property-decorator';

@Emit('update:visible')
emitVisible(visible: boolean) {
  // return value becomes the emitted payload
}

@Emit()
submit(data: FormData) {
  // method name becomes event name (kebab-case): 'submit'
}
```

**Vue3:**
```typescript
const emit = defineEmits<{
  (e: 'update:visible', value: boolean): void;
  (e: 'submit', data: FormData): void;
  (e: 'cancel'): void;
}>();

function handleVisible(visible: boolean) {
  emit('update:visible', visible);
}

function handleSubmit(data: FormData) {
  emit('submit', data);
}
```

**Note**: With `vue-property-decorator`, `@Emit()` auto-converts method name to kebab-case. With `defineEmits` you must explicitly write the kebab-case event name.

---

### @Ref → ref (template ref)

**Vue2:**
```typescript
import { Ref } from 'vue-property-decorator';

@Ref('myDiv') readonly divRef!: HTMLDivElement;
@Ref() readonly childComp!: ChildComp;
```

**Vue3:**
```typescript
const divRef = ref<HTMLDivElement | null>(null);
const childComp = ref<InstanceType<typeof ChildComp> | null>(null);
```
Template: `<div ref="divRef">` and `<ChildComp ref="childComp" />`.

Variable name MUST match the template `ref` attribute.

---

### @Provide/@Inject → provide/inject

**Vue2:**
```typescript
import { Provide, Inject } from 'vue-property-decorator';
import { ProvideReactive, InjectReactive } from 'vue-property-decorator';

// Provider
@Provide() theme = 'dark';
@ProvideReactive() user = { name: 'John' };

// Consumer
@Inject() readonly theme!: string;
@InjectReactive() readonly user!: User;
```

**Vue3:**
```typescript
import { provide, inject, ref, type Ref, type InjectionKey } from 'vue';

// Provider
const theme = ref('dark');
provide('theme', theme);
provide('theme', readonly(theme)); // if you want consumers to not mutate

// Consumer
const theme = inject<string>('theme', 'light'); // with default
const user = inject<User>('user');
```

**WARNING**: In Vue2, `@ProvideReactive` creates a reactive relationship. In Vue3, providing a `ref` IS reactive by default. Providing a plain value is NOT reactive.

---

### Lifecycle Methods

**Vue2 class:**
```typescript
mounted() { /* ... */ }
beforeDestroy() { /* ... */ }
```

**Vue3:**
```typescript
import { onMounted, onBeforeUnmount } from 'vue';

onMounted(() => { /* ... */ });
onBeforeUnmount(() => { /* ... */ });
```

**Name changes:**
- `beforeDestroy` → `onBeforeUnmount`
- `destroyed` → `onUnmounted`

---

### Computed Properties

**Vue2 class:**
```typescript
get fullName(): string {
  return this.firstName + ' ' + this.lastName;
}
set fullName(val: string) {
  const parts = val.split(' ');
  this.firstName = parts[0];
  this.lastName = parts[1];
}
```

**Vue3:**
```typescript
const fullName = computed({
  get: () => props.firstName + ' ' + props.lastName,
  set: (val: string) => {
    const parts = val.split(' ');
    emit('update:firstName', parts[0]);
    emit('update:lastName', parts[1]);
  },
});
```

---

### Data Properties → ref / reactive

**Vue2:**
```typescript
private loading = false;
private items: Item[] = [];
private formData = { name: '', email: '' };
```

**Vue3:**
```typescript
const loading = ref(false);
const items = ref<Item[]>([]);
const formData = reactive({ name: '', email: '' });
```

**Rule of thumb**: Use `ref()` for primitives and arrays. Use `reactive()` for objects with known shape. NEVER destructure a reactive object — use `toRefs()` if needed.

---

### Methods → Functions

**Vue2:**
```typescript
private async fetchData(): Promise<void> {
  this.loading = true;
  try {
    this.items = await api.getItems();
  } finally {
    this.loading = false;
  }
}
```

**Vue3:**
```typescript
async function fetchData(): Promise<void> {
  loading.value = true;
  try {
    items.value = await api.getItems();
  } finally {
    loading.value = false;
  }
}
```

**CRITICAL**: Every access to a `ref` inside `<script setup>` requires `.value`. This is the #1 cause of migration errors. Every `this.xxx` in Vue2 becomes `xxx.value` in Vue3.

---

## Common Pitfalls

### 1. Forgetting `.value` on refs
Vue2 class: `this.loading = true`
Vue3: `loading.value = true` (NOT `loading = true`)

### 2. Watch getter vs value
Vue2: `@Watch('title')` watches the prop named 'title'.
Vue3: `watch(props.title, ...)` is WRONG. Use `watch(() => props.title, ...)`.

### 3. Destructuring props
NEVER do `const { title } = defineProps<...>()`. This loses reactivity. Use `props.title` or `toRefs(props)`.

### 4. Class private → nothing in script setup
`private someMethod()` has no direct equivalent. Everything in `<script setup>` is scoped to the component. Just write `function someMethod()`.

### 5. Template ref name mismatch
Vue2: `@Ref('myDiv') readonly divRef` with `<div ref="myDiv">`
Vue3: `const divRef = ref()` with `<div ref="divRef">` — variable name MUST match template ref attribute.

### 6. Mixins with same lifecycle
If a class component used mixins that all had `mounted()`, only the component's own `mounted()` ran (class syntax limitation). In Vue3 composables, `onMounted()` calls from multiple composables ALL run. Verify there are no duplicate side effects.
