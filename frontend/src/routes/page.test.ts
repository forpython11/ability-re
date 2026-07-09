import { render, screen } from '@testing-library/svelte';
import { describe, expect, it } from 'vitest';
import Page from './+page.svelte';

const data = {
  home: {
    hero: {
      title: '用新技术重构你的数字能力',
      subtitle: '测试副标题',
    },
    features: [
      { title: '前后端分离', description: '职责清晰', icon: 'layers' },
      { title: '数据库驱动', description: '内容入库', icon: 'database' },
      { title: '工程化基础', description: '测试构建', icon: 'sparkles' },
    ],
  },
  apiAvailable: true,
};

describe('landing page', () => {
  it('renders hero and feature cards', () => {
    render(Page, { props: { data } });

    expect(screen.getByRole('heading', { name: '用新技术重构你的数字能力' })).toBeInTheDocument();
    expect(screen.getByText('前后端分离')).toBeInTheDocument();
    expect(screen.getByText('数据库驱动')).toBeInTheDocument();
    expect(screen.getByText('工程化基础')).toBeInTheDocument();
  });
});
