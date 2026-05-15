# Webpack to Vite Migration

## Package Changes

**Remove:**
```json
"@vue/cli-plugin-babel",
"@vue/cli-plugin-router",
"@vue/cli-plugin-typescript",
"@vue/cli-plugin-vuex",
"@vue/cli-service",
"vue-template-compiler",
"babel-eslint",
"babel-loader",  // and all babel plugins
```

**Add:**
```json
"vite": "^5.x",
"@vitejs/plugin-vue": "^5.x",
"vite-plugin-vue-devtools": "^7.x",  // optional, replaces Vue Devtools
"unplugin-auto-import": "^0.x",       // optional, auto-import Vue APIs
"unplugin-vue-components": "^0.x",    // optional, auto-import components
"rollup-plugin-visualizer": "^5.x",   // optional, bundle analysis
```

---

## vite.config.ts

**Before (vue.config.js):**
```javascript
const path = require('path');

module.exports = {
  publicPath: '/',
  outputDir: 'dist',
  assetsDir: 'static',
  devServer: {
    port: 8080,
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true,
      },
    },
  },
  configureWebpack: {
    resolve: {
      alias: {
        '@': path.resolve(__dirname, 'src'),
      },
    },
  },
  chainWebpack: (config) => {
    config.plugin('html').tap((args) => {
      args[0].title = 'My App';
      return args;
    });
  },
};
```

**After (vite.config.ts):**
```typescript
import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import { resolve } from 'path';

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
    },
  },
  server: {
    port: 8080,
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true,
      },
    },
  },
  build: {
    outDir: 'dist',
    assetsDir: 'static',
  },
});
```

---

## index.html

Vite requires `index.html` at the project root (NOT in `public/`).

**Before**: `public/index.html` with `<%= htmlWebpackPlugin.options.title %>` and other EJS template variables.

**After**: `index.html` (project root):
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <link rel="icon" href="/favicon.ico" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>My App</title>
</head>
<body>
  <div id="app"></div>
  <script type="module" src="/src/main.ts"></script>
</body>
</html>
```

**CRITICAL**: Add `<script type="module" src="/src/main.ts">` — this is what Vite uses as the entry point. No EJS, no template variables. Hard-code the title or use a Vite plugin.

---

## Environment Variables

**Before:** `process.env.VUE_APP_API_URL`

**After:** `import.meta.env.VITE_API_URL`

Rename all variables:
- `VUE_APP_*` → `VITE_*` (in `.env` files AND in code)
- `.env.development`, `.env.production` files remain the same but variable names change

Search and replace:
```bash
grep -rn "process\.env\.VUE_APP_" --include="*.ts" --include="*.vue" --include="*.js" src/
```

---

## Dynamic Imports

**Before:**
```typescript
const component = () => import('@/views/MyComponent.vue');
// or with webpack chunk name:
const component = () => import(/* webpackChunkName: "my-chunk" */ '@/views/MyComponent.vue');
```

**After:**
```typescript
const component = () => import('@/views/MyComponent.vue');
// Vite uses the file path as chunk name by default. No magic comments needed.
```

---

## require() → import or URL

**Before:**
```typescript
const img = require('@/assets/logo.png');
```

**After:**
```typescript
import img from '@/assets/logo.png';
// OR for dynamic paths:
const imgUrl = new URL(`@/assets/${name}.png`, import.meta.url).href;
```

Search ALL `require()` calls — Vite does NOT support CommonJS `require()`.

---

## TypeScript Config Changes

**tsconfig.json** additions:
```json
{
  "compilerOptions": {
    "module": "ESNext",
    "moduleResolution": "bundler",
    "types": ["vite/client"],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src/**/*.ts", "src/**/*.d.ts", "src/**/*.vue", "env.d.ts"]
}
```

**env.d.ts** (create if missing):
```typescript
/// <reference types="vite/client" />

declare module '*.vue' {
  import type { DefineComponent } from 'vue';
  const component: DefineComponent<{}, {}, any>;
  export default component;
}
```

---

## Common Pitfalls

### 1. process.env → import.meta.env
The #1 build failure after migration. Every `process.env.*` must become `import.meta.env.*`. This includes `process.env.NODE_ENV` → `import.meta.env.MODE`.

### 2. require() in any .ts/.vue file
Vite uses native ESM. Any `require()` call will fail at build time. Common offenders:
- `require('path')` → `import path from 'path'`
- `require.context(...)` → `import.meta.glob(...)` or `import.meta.globEager(...)`

### 3. require.context → import.meta.glob

**Before:**
```typescript
const modules = require.context('./modules', true, /\.ts$/);
modules.keys().forEach((key) => { /* ... */ });
```

**After:**
```typescript
const modules = import.meta.glob('./modules/**/*.ts', { eager: true });
Object.entries(modules).forEach(([key, module]) => { /* ... */ });
```

### 4. public/ → public/ (unchanged but behaviors differ)
Files in `public/` are served at root (unchanged). BUT Vite does NOT process them through the bundler, so no hash in filenames.

### 5. __dirname in vite.config.ts
`__dirname` works in vite.config.ts (it's a Node.js file). But NOT in browser code. For browser-side path resolution, use `import.meta.url`.

### 6. SCSS / Less additionalData → css.preprocessorOptions

**Before (vue.config.js):**
```javascript
css: {
  loaderOptions: {
    scss: {
      additionalData: `@import "@/styles/variables.scss";`,
    },
  },
},
```

**After (vite.config.ts):**
```typescript
css: {
  preprocessorOptions: {
    scss: {
      additionalData: `@use "@/styles/variables.scss" as *;`,
    },
  },
},
```

**Note**: Vite uses the modern Sass API. `@import` is deprecated; use `@use` instead. If the project has many `@import`-based SCSS files, this may require bulk changes.
