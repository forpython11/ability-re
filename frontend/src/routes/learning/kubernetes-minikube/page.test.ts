import { render, screen } from '@testing-library/svelte';
import { describe, expect, it } from 'vitest';
import Page from './+page.svelte';

// 使用一份最小但完整的路由数据，测试不依赖真实后端或数据库。
const data = {
  record: {
    slug: 'kubernetes-minikube',
    title: '数据库返回的 Kubernetes 学习记录标题',
    summary: '数据库返回的真实学习记录摘要',
    category: 'Kubernetes learning record',
    environment: 'macOS Intel / Docker Desktop',
    publishedAt: '2026-07-14',
    blocks: [
      {
        type: 'section',
        heading: '我到底做了什么',
        body: '这次实践完成的是一条最小但完整的 Kubernetes 本地部署链路。',
        codeSample: null,
      },
      {
        type: 'result',
        heading: '最终跑通的结果',
        body: 'Nginx 测试 Pod 已达到 1/1 Running。',
        codeSample: 'kubectl get pods',
      },
    ],
  },
  apiAvailable: true,
};

describe('kubernetes learning record page', () => {
  it('renders learning record from route data', () => {
    // render 模拟 SvelteKit 把 server load 结果作为 data 传给页面。
    render(Page, { props: { data } });

    expect(screen.getByRole('heading', { name: data.record.title })).toBeInTheDocument();
    expect(screen.getByText(data.record.summary)).toBeInTheDocument();
    expect(screen.getByText('我到底做了什么')).toBeInTheDocument();
    expect(screen.getByText('kubectl get pods')).toBeInTheDocument();
  });
});
