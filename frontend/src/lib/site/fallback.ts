import type { HomePage } from '$lib/api/types';

export const fallbackHomePage: HomePage = {
  hero: {
    title: '用新技术重构你的数字能力',
    subtitle: 'Ability Re 是一个前后端分离官网示例，使用 SvelteKit、Spring Boot 和 MySQL 打造现代化展示与线索收集体验。',
  },
  features: [
    {
      title: '前后端分离',
      description: 'SvelteKit 负责页面体验，Spring Boot 负责业务 API，边界清晰，方便团队协作。',
      icon: 'layers',
    },
    {
      title: '数据库驱动',
      description: 'MySQL 保存官网内容与联系线索，Flyway 管理表结构版本。',
      icon: 'database',
    },
    {
      title: '工程化基础',
      description: 'TypeScript、Java 21、测试、配置隔离和 Docker 数据库脚本作为项目起点。',
      icon: 'sparkles',
    },
  ],
};
