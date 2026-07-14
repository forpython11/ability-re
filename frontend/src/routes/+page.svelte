<script lang="ts">
  import type { HomePage } from '$lib/api/types';

  type PageData = {
    home: HomePage;
    apiAvailable: boolean;
  };

  let { data }: { data: PageData } = $props();

</script>

<svelte:head>
  <title>能力重构 - 个人技术记录</title>
  <meta
    name="description"
    content="能力重构是个人维护的技术记录网站，用于展示 Web 开发学习、项目实践和部署经验。"
  />
</svelte:head>

<header class="site-header">
  <a class="brand" href="#top">能力重构</a>
  <nav aria-label="主导航">
    <a href="#features">记录</a>
    <a href="#about">关于</a>
    <a href="#notice">说明</a>
  </nav>
</header>

<main id="top">
  <section class="hero">
    <div class="hero-copy">
      <p class="eyebrow">个人技术学习与项目展示</p>
      <h1>{data.home.hero.title}</h1>
      <p class="subtitle">{data.home.hero.subtitle}</p>
      <div class="actions">
        <a class="button primary" href="#features">查看记录</a>
        <a class="button ghost" href="#about">了解本站</a>
      </div>
      {#if !data.apiAvailable}
        <p class="api-tip">当前使用前端兜底内容；启动后端后会自动读取数据库内容。</p>
      {/if}
    </div>
    <div class="hero-card" aria-label="本站内容方向">
      <span>前端学习</span>
      <strong>SvelteKit</strong>
      <span>后端实践</span>
      <strong>Spring Boot</strong>
      <span>部署记录</span>
      <strong>Linux / MySQL</strong>
    </div>
  </section>

  <section id="features" class="section">
    <div class="section-heading">
      <p class="eyebrow">Learning notes</p>
      <h2>记录个人在 Web 开发中的学习和实践</h2>
    </div>
    <div class="feature-grid">
      {#each data.home.features as feature}
        <article class="feature-card">
          <div class="icon">{feature.icon}</div>
          <h3>{feature.title}</h3>
          <p>{feature.description}</p>
        </article>
      {/each}
    </div>
  </section>

  <section id="about" class="section split-section">
    <div>
      <p class="eyebrow">About</p>
      <h2>一个面向个人学习沉淀的网站</h2>
    </div>
    <p>
      本站由个人维护，用来整理前端框架、Java 后端、数据库和部署相关的学习过程。
      页面内容仅用于个人技术展示与经验记录，不提供在线交易、付费咨询、广告推广或会员服务。
    </p>
  </section>

  <section id="notice" class="section notice-section">
    <div>
      <p class="eyebrow">Site notice</p>
      <h2>备案与隐私说明</h2>
    </div>
    <div class="notice-card">
      <p>本站暂无注册、评论、支付和在线交易功能，不主动收集访客个人信息。</p>
      <p>ICP备案号将在备案通过后按要求补充展示。</p>
      <p>主办者性质：个人。网站用途：个人技术学习记录与项目展示。</p>
    </div>
  </section>
</main>

<footer class="site-footer">
  <span>能力重构</span>
  <span>个人技术记录网站</span>
  <span>ICP备案号：备案成功后补充</span>
</footer>
