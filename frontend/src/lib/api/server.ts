import { env } from '$env/dynamic/private';
import type { ApiResponse, HomePage, LearningRecord } from './types';

// 本地开发的默认后端地址；容器部署时由私有环境变量 API_BASE_URL 覆盖。
const defaultBaseUrl = 'http://127.0.0.1:18080';

/** 在 SvelteKit 服务端统一完成请求、状态检查和 ApiResponse 解包。 */
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
    // 让页面 load 函数决定是使用兜底内容，还是显示错误状态。
    throw new Error(`API request failed: ${response.status}`);
  }

  // 后端返回 { code, message, data }，页面只需要其中的 data。
  const body = (await response.json()) as ApiResponse<T>;
  return body.data;
}

export function getHomePage(fetcher: typeof fetch): Promise<HomePage> {
  return request<HomePage>(fetcher, '/api/site/home');
}

export function getLearningRecord(fetcher: typeof fetch, slug: string): Promise<LearningRecord> {
  return request<LearningRecord>(fetcher, `/api/site/learning-records/${slug}`);
}
