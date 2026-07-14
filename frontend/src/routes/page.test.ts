import { render, screen } from '@testing-library/svelte';
import { describe, expect, it } from 'vitest';
import Page from './+page.svelte';

const data = {
  home: {
    hero: {
      title: '能力重构个人技术记录',
      subtitle: '测试副标题',
    },
    features: [
      { title: '前端学习笔记', description: '职责清晰', icon: 'layers' },
      { title: '后端工程实践', description: '内容入库', icon: 'database' },
      { title: '部署与数据库记录', description: '测试构建', icon: 'sparkles' },
    ],
  },
  apiAvailable: true,
};

describe('landing page', () => {
  it('renders hero and feature cards', () => {
    render(Page, { props: { data } });

    expect(screen.getByRole('heading', { name: '能力重构个人技术记录' })).toBeInTheDocument();
    expect(screen.getByText('前端学习笔记')).toBeInTheDocument();
    expect(screen.getByText('后端工程实践')).toBeInTheDocument();
    expect(screen.getByText('部署与数据库记录')).toBeInTheDocument();
    expect(screen.getByText('个人技术记录网站')).toBeInTheDocument();
  });
});
