import { env } from '$env/dynamic/private';
import type { ApiResponse, HomePage, LearningRecord } from './types';

const defaultBaseUrl = 'http://127.0.0.1:18080';

async function request<T>(fetcher: typeof fetch, path: string, init?: RequestInit): Promise<T> {
  const baseUrl = env.API_BASE_URL || defaultBaseUrl;
  const response = await fetcher(`${baseUrl}${path}`, {
    headers: {
      'Content-Type': 'application/json',
      ...init?.headers,
    },
    ...init,
  });

  if (!response.ok) {
    throw new Error(`API request failed: ${response.status}`);
  }

  const body = (await response.json()) as ApiResponse<T>;
  return body.data;
}

export function getHomePage(fetcher: typeof fetch): Promise<HomePage> {
  return request<HomePage>(fetcher, '/api/site/home');
}

export function getLearningRecord(fetcher: typeof fetch, slug: string): Promise<LearningRecord> {
  return request<LearningRecord>(fetcher, `/api/site/learning-records/${slug}`);
}
