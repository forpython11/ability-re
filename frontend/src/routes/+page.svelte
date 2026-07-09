<script lang="ts">
  import { submitContact } from '$lib/api/client';
  import type { ContactPayload, HomePage } from '$lib/api/types';

  type PageData = {
    home: HomePage;
    apiAvailable: boolean;
  };

  let { data }: { data: PageData } = $props();

  let form = $state<ContactPayload>({
    name: '',
    email: '',
    company: '',
    message: '',
  });
  let submitting = $state(false);
  let submitMessage = $state('');

  async function handleSubmit() {
    submitting = true;
    submitMessage = '';

    try {
      await submitContact(form);
      submitMessage = '提交成功，我们已经把你的信息保存到数据库。';
      form = { name: '', email: '', company: '', message: '' };
    } catch {
      submitMessage = '提交失败，请确认后端服务已经启动。';
    } finally {
      submitting = false;
    }
  }
</script>

<svelte:head>
  <title>Ability Re - 前后端分离官网</title>
  <meta
    name="description"
    content="Ability Re 是基于 SvelteKit、Spring Boot 和 MySQL 的前后端分离官网项目。"
  />
</svelte:head>

<header class="site-header">
  <a class="brand" href="#top">Ability Re</a>
  <nav aria-label="主导航">
    <a href="#features">能力</a>
    <a href="#about">关于</a>
    <a href="#contact">联系</a>
  </nav>
</header>

<main id="top">
  <section class="hero">
    <div class="hero-copy">
      <p class="eyebrow">SvelteKit · Spring Boot · MySQL</p>
      <h1>{data.home.hero.title}</h1>
      <p class="subtitle">{data.home.hero.subtitle}</p>
      <div class="actions">
        <a class="button primary" href="#contact">预约咨询</a>
        <a class="button ghost" href="#features">查看能力</a>
      </div>
      {#if !data.apiAvailable}
        <p class="api-tip">当前使用前端兜底内容；启动后端后会自动读取数据库内容。</p>
      {/if}
    </div>
    <div class="hero-card" aria-label="项目技术栈">
      <span>Frontend</span>
      <strong>SvelteKit</strong>
      <span>Backend</span>
      <strong>Spring Boot 3</strong>
      <span>Database</span>
      <strong>MySQL</strong>
    </div>
  </section>

  <section id="features" class="section">
    <div class="section-heading">
      <p class="eyebrow">Core capabilities</p>
      <h2>从官网开始，搭出可扩展的产品入口</h2>
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
      <p class="eyebrow">Why this stack</p>
      <h2>既能学新前端，也能补齐主流后端工程</h2>
    </div>
    <p>
      SvelteKit 帮你从 Vue 经验过渡到编译型前端框架；Spring Boot 负责标准企业后端结构；MySQL 和 Flyway
      让官网内容、联系线索和数据库版本从第一天就有清晰边界。
    </p>
  </section>

  <section id="contact" class="section contact-section">
    <div>
      <p class="eyebrow">Contact</p>
      <h2>把联系线索写入数据库</h2>
      <p>表单会调用后端 <code>POST /api/contact</code>，由 Spring Boot 校验后保存到 MySQL。</p>
    </div>

    <form onsubmit={(event) => { event.preventDefault(); handleSubmit(); }}>
      <label>
        姓名
        <input bind:value={form.name} name="name" required maxlength="80" />
      </label>
      <label>
        邮箱
        <input bind:value={form.email} name="email" type="email" required maxlength="160" />
      </label>
      <label>
        公司
        <input bind:value={form.company} name="company" maxlength="160" />
      </label>
      <label>
        需求描述
        <textarea bind:value={form.message} name="message" required minlength="10" maxlength="2000"></textarea>
      </label>
      <button class="button primary" type="submit" disabled={submitting}>
        {submitting ? '提交中...' : '提交需求'}
      </button>
      {#if submitMessage}
        <p class="submit-message">{submitMessage}</p>
      {/if}
    </form>
  </section>
</main>
