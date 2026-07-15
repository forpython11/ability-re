// @ts-nocheck
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vitest/config';

// Vite 负责开发/构建，Vitest 复用同一配置运行 Svelte 组件测试。
export default defineConfig({
  plugins: [sveltekit()],
  resolve: {
    conditions: ['browser'],
  },
  test: {
    // jsdom 在 Node 中模拟浏览器 DOM，测试不需要启动真实浏览器。
    environment: 'jsdom',
    include: ['src/**/*.test.ts'],
    setupFiles: ['./src/test-setup.ts'],
  },
});
