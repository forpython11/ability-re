import { getLearningRecord } from '$lib/api/server';
import type { PageServerLoad } from './$types';

// 当前只有一篇固定路由文章，所以 slug 在服务端写死；以后可改成 [slug] 动态路由。
export const load: PageServerLoad = async ({ fetch }) => {
  const slug = 'kubernetes-minikube';

  try {
    return {
      record: await getLearningRecord(fetch, slug),
      apiAvailable: true,
    };
  } catch {
    // 与首页不同，文章页暂不使用静态正文兜底，而是明确展示数据库不可用状态。
    return {
      record: null,
      apiAvailable: false,
    };
  }
};
