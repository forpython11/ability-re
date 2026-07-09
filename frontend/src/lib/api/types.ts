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
};

export type ContactPayload = {
  name: string;
  email: string;
  company?: string;
  message: string;
};

export type ContactResult = {
  id: number;
  status: string;
};
