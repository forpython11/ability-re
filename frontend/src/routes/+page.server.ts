import { getHomePage } from '$lib/api/server';
import { fallbackHomePage } from '$lib/site/fallback';
import type { PageServerLoad } from './$types';

// +page.server.ts 只在服务端运行，因此内部 API 地址不会暴露给浏览器。
export const load: PageServerLoad = async ({ fetch }) => {
  try {
    return {
      home: await getHomePage(fetch),
      apiAvailable: true,
    };
  } catch {
    // 数据库或后端短暂不可用时仍返回可阅读首页，并把状态交给页面提示用户。
    return {
      home: fallbackHomePage,
      apiAvailable: false,
    };
  }
};
