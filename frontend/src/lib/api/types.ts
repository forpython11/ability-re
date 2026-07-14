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
  blocks: Array<{
    type: string;
    heading: string;
    body: string;
    codeSample: string | null;
  }>;
};
