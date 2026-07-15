import { render, screen } from '@testing-library/svelte';
import { describe, expect, it } from 'vitest';
import Page from './+page.svelte';

// 页面测试使用内存数据，确保失败时定位到模板，而不是网络环境。
const data = {
  home: {
    hero: {
      title: '能力重构个人技术记录',
      subtitle: '测试副标题',
    },
    features: [
      { title: '前端学习笔记', description: '职责清晰', icon: 'layers' },
      { title: '后端工程实践', description: '内容入库', icon: 'database' },
      { title: '部署与 Kubernetes 记录', description: '测试构建', icon: 'sparkles' },
    ],
    learningRecords: [
      {
        slug: 'kubernetes-minikube',
        title: '数据库返回的 Kubernetes 学习记录标题',
        summary: '数据库返回的完整学习记录入口摘要',
        category: 'Kubernetes learning record',
      },
    ],
  },
  apiAvailable: true,
};

describe('landing page', () => {
  it('renders hero, feature cards and learning record entry', () => {
    // 从用户能看到的标题、文字和链接验证首页，而不是依赖内部 DOM 结构。
    render(Page, { props: { data } });

    expect(screen.getByRole('heading', { name: '能力重构个人技术记录' })).toBeInTheDocument();
    expect(screen.getByText('前端学习笔记')).toBeInTheDocument();
    expect(screen.getByText('后端工程实践')).toBeInTheDocument();
    expect(screen.getByText('部署与 Kubernetes 记录')).toBeInTheDocument();
    expect(screen.getByText('完整学习记录单独成页')).toBeInTheDocument();
    expect(screen.getByText('数据库返回的 Kubernetes 学习记录标题')).toBeInTheDocument();
    expect(screen.getByRole('link', { name: '查看完整学习记录' })).toHaveAttribute(
      'href',
      '/learning/kubernetes-minikube',
    );
    expect(screen.getByText('个人技术记录网站')).toBeInTheDocument();
  });
});
