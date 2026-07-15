import type { HomePage, LearningRecord } from './types';

// 这些占位函数用于阻止浏览器直接请求内部后端地址；页面应通过 server.ts 在服务端取数。
export function getHomePage(): Promise<HomePage> {
  throw new Error('getHomePage is server-only; use $lib/api/server from +page.server.ts');
}

export function getLearningRecord(_slug: string): Promise<LearningRecord> {
  throw new Error('getLearningRecord is server-only; use $lib/api/server from +page.server.ts');
}
