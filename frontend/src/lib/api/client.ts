import type { HomePage, LearningRecord } from './types';

export function getHomePage(): Promise<HomePage> {
  throw new Error('getHomePage is server-only; use $lib/api/server from +page.server.ts');
}

export function getLearningRecord(_slug: string): Promise<LearningRecord> {
  throw new Error('getLearningRecord is server-only; use $lib/api/server from +page.server.ts');
}
