// 这些类型与 Spring Boot 的响应 DTO 保持一致，用于在编译期检查字段名。
export type ApiResponse<T> = {
  code: number;
  message: string;
  data: T;
};

export type HomePage = {
  hero: {
    title: string;
    subtitle: string;
  };
  features: Array<{
    title: string;
    description: string;
    icon: string;
  }>;
  learningRecords: Array<{
    slug: string;
    title: string;
    summary: string;
    category: string;
  }>;
};

export type LearningRecord = {
  slug: string;
  title: string;
  summary: string;
  category: string;
  environment: string;
  publishedAt: string;
  // 后端把长文章拆成有顺序的正文块，前端再逐块渲染。
  blocks: Array<{
    type: string;
    heading: string;
    body: string;
    codeSample: string | null;
  }>;
};
