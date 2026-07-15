<script lang="ts">
  import type { LearningRecord } from '$lib/api/types';

  type PageData = {
    record: LearningRecord | null;
    apiAvailable: boolean;
  };

  let { data }: { data: PageData } = $props();
  // $derived 会在路由数据变化时重新计算，避免复制出不同步的页面状态。
  const record = $derived(data.record);
  const apiAvailable = $derived(data.apiAvailable);
  const pageTitle = $derived(record?.title ?? 'Kubernetes / Minikube 学习记录');
  const pageDescription = $derived(record?.summary ?? 'Kubernetes / Minikube 学习记录暂时无法从数据库加载。');
</script>

<svelte:head>
  <title>{pageTitle} - 能力重构</title>
  <meta name="description" content={pageDescription} />
</svelte:head>

<header class="site-header">
  <a class="brand" href="/">能力重构</a>
  <nav aria-label="学习记录导航">
    <a href="/">首页</a>
    <a href="#content">正文</a>
    <a href="#capability">能力</a>
  </nav>
</header>

<main class="article-page">
  {#if record}
    <!-- 数据加载成功：先显示文章元信息，再按数据库顺序渲染正文块。 -->
    <article class="article-shell">
      <header class="article-hero">
        <p class="eyebrow">{record.category}</p>
        <h1>{record.title}</h1>
        <p class="article-lead">{record.summary}</p>
        <div class="meta-list" aria-label="实践环境">
          <span>{record.environment}</span>
          <span>{record.publishedAt}</span>
          <span>{apiAvailable ? '数据库内容' : '前端兜底内容'}</span>
        </div>
      </header>

      <div id="content" class="article-content">
        {#each record.blocks as block}
          <section class="article-section" id={block.type === 'capability' ? 'capability' : undefined}>
            <h2>{block.heading}</h2>
            <!-- 数据库用两个换行分隔自然段，页面在这里恢复成多个 p 元素。 -->
            {#each block.body.split('\n\n') as paragraph}
              <p>{paragraph}</p>
            {/each}
            {#if block.codeSample}
              <pre><code>{block.codeSample}</code></pre>
            {/if}
          </section>
        {/each}
      </div>
    </article>
  {:else}
    <!-- 数据加载失败：保留清晰提示，避免页面完全空白。 -->
    <section class="article-hero">
      <p class="eyebrow">Kubernetes learning record</p>
      <h1>学习记录暂时无法加载</h1>
      <p class="article-lead">这页内容来自后端数据库。当前预览没有获取到数据库记录，请先启动后端服务并确认 API 可访问。</p>
      <div class="meta-list" aria-label="加载状态">
        <span>数据库内容未加载</span>
      </div>
    </section>
  {/if}

  <a class="text-link" href="/">返回首页</a>
</main>
