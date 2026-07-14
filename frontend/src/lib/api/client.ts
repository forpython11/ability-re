import type { ApiResponse, ContactPayload, ContactResult, HomePage } from './types';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? '';

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(`${API_BASE_URL}${path}`, {
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

export function getHomePage(): Promise<HomePage> {
  return request<HomePage>('/api/site/home');
}

export function submitContact(payload: ContactPayload): Promise<ContactResult> {
  return request<ContactResult>('/api/contact', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}
