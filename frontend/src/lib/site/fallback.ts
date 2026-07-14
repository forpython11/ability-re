import type { HomePage } from '$lib/api/types';

export const fallbackHomePage: HomePage = {
  hero: {
    title: '能力重构个人技术记录',
    subtitle: '这里记录个人在 SvelteKit、Spring Boot、MySQL 和服务器部署中的学习过程与项目实践。',
  },
  features: [
    {
      title: '前端学习笔记',
      description: '整理 SvelteKit、TypeScript、页面结构和交互体验相关的学习记录。',
      icon: 'layers',
    },
    {
      title: '后端工程实践',
      description: '记录 Spring Boot、接口设计、参数校验和自动化测试的实践过程。',
      icon: 'database',
    },
    {
      title: '部署与数据库记录',
      description: '沉淀 Linux、Docker、MySQL、Flyway 和日常部署排查经验。',
      icon: 'sparkles',
    },
  ],
};
