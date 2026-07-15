# 能力重构网站 SEO 优化方案

## 1. 目标与范围

### 目标

- 让搜索引擎能够通过稳定的正式域名抓取、理解并收录首页和技术文章。
- 围绕 SvelteKit、Spring Boot、Docker、Kubernetes 等主题获取非品牌自然搜索流量。
- 建立可持续扩展的文章发布、站内链接、站点地图和效果复盘机制。

### 默认业务假设

- 第一目标为自然搜索获客，第二目标为“能力重构”品牌词收录。
- 内容以中文原创技术实战为主，暂不做多语言站点。
- 首期不引入大型 CMS，不做关键词堆砌、批量低质量页面或购买外链。
- 不承诺固定流量数值；新站增长取决于域名、内容质量、发布频率和搜索需求。

## 2. 现状审计

### 已有基础

- 前端使用 SvelteKit SSR，线上 HTML 已直接包含正文，不依赖爬虫执行 JavaScript；技术栈见 `frontend/package.json:14-25` 和 `frontend/svelte.config.js:1-9`。
- 全局语言为 `zh-CN`，见 `frontend/src/app.html:1-6`。
- 首页已有唯一 `title`、`description` 和 `h1`，见 `frontend/src/routes/+page.svelte:13-19`、`frontend/src/routes/+page.svelte:31-36`。
- 文章页已有动态 `title`、`description`、一个 `h1` 和分层 `h2`，见 `frontend/src/routes/learning/kubernetes-minikube/+page.svelte:12-19`、`frontend/src/routes/learning/kubernetes-minikube/+page.svelte:30-55`。
- 首页文章卡片使用可抓取的普通链接，见 `frontend/src/routes/+page.svelte:78-85`。

### 当前阻塞项

1. **没有稳定的正式域名和 HTTPS**
   - 当前生产地址仍为 `http://8.136.60.154:18081`，见 `.env.example:3`、`DEPLOYMENT_CHECKLIST.md:3-13`。
   - Nginx 仅监听 80，且 `server_name _`，见 `nginx.conf:3-5`。
   - 这会阻碍 canonical、站长平台验证、品牌搜索和长期链接权重沉淀。

2. **抓取入口不完整**
   - 2026-07-15 线上实测 `/robots.txt` 和 `/sitemap.xml` 均返回 404。
   - 仓库内没有 robots、sitemap、canonical、Open Graph 或 JSON-LD 实现。

3. **文章扩展后会产生死链**
   - 后端能按任意 slug 返回详情，见 `backend/src/main/java/com/abilityre/site/SiteController.java:23-25`。
   - 首页会列出数据库中的所有记录，见 `backend/src/main/java/com/abilityre/site/SiteService.java:25-47`。
   - 前端详情页目录和 slug 却固定为 `kubernetes-minikube`，见 `frontend/src/routes/learning/kubernetes-minikube/+page.server.ts:4-10`。

4. **文章故障页是软 404**
   - 加载失败后返回 `record: null`，见 `frontend/src/routes/learning/kubernetes-minikube/+page.server.ts:7-17`。
   - 页面显示“暂时无法加载”，但 HTTP 状态仍为 200，见 `frontend/src/routes/learning/kubernetes-minikube/+page.svelte:58-67`。
   - 后端缺失记录抛普通参数异常，且没有 404 映射，见 `backend/src/main/java/com/abilityre/site/SiteService.java:50-53`、`backend/src/main/java/com/abilityre/common/GlobalExceptionHandler.java:11-20`。

5. **内容规模与数据模型不足**
   - 当前仅有一篇技术文章，见 `backend/src/main/resources/db/migration/V3__learning_records.sql:31-37`。
   - 数据库有 `updated_at`，但实体和接口仅暴露 `publishedAt`，见 `backend/src/main/resources/db/migration/V3__learning_records.sql:8-10`、`backend/src/main/java/com/abilityre/site/LearningRecordResponse.java:6-13`。
   - 缺少作者、更新时间、发布状态、SEO 标题和描述等可维护字段。

## 3. 执行优先级

| 优先级 | 工作 | 目的 | 建议周期 |
| --- | --- | --- | --- |
| P0 | 域名、HTTPS、唯一主站、动态路由、状态码、robots、sitemap、canonical | 保证可抓取、可归一、可正确收录 | 第 1 周 |
| P1 | OG、JSON-LD、文章模型、聚合页、内链、图片资产 | 提高页面理解和搜索/分享展示质量 | 第 2 周 |
| P1 | 主题内容集群与稳定发布 | 建立关键词覆盖和内容权威性 | 第 3-6 周 |
| P2 | 站长平台、Core Web Vitals、月度复盘 | 形成数据反馈闭环 | 域名上线后持续 |

## 4. 实施步骤

### 阶段 A：建立唯一生产地址

1. 购买并完成可用域名、备案和 DNS 配置，将域名解析到当前 ECS。
2. 配置 TLS 证书，只保留一个规范主机名；其他 host、IP 访问和 HTTP 全部 301 到规范地址。
3. 将 `FRONTEND_ORIGIN` 和新增的 `PUBLIC_SITE_URL` 配成规范 HTTPS 地址，涉及 `.env.example`、`frontend/.env.example`、`docker-compose.yml:58-63`。
4. 在 `nginx.conf:3-33` 增加明确的 `server_name`、80 到 443 跳转、证书配置，并保留转发头。
5. 更新 `DEPLOYMENT_CHECKLIST.md`，记录 DNS、证书续期、301 和回滚检查项。

验收：

- `http://域名/*`、IP 地址和非规范 host 均只经过一次 301 到 `https://规范域名/*`。
- 规范域名证书有效，页面无混合内容，所有 SSR 页面 canonical 使用相同 origin。
- 不将端口号、localhost 或内网地址输出到公开 meta、robots 或 sitemap。

### 阶段 B：修复路由和 HTTP 语义

1. 将固定目录 `frontend/src/routes/learning/kubernetes-minikube/` 改为 `frontend/src/routes/learning/[slug]/`。
2. 在新的 `+page.server.ts` 使用 `params.slug` 请求后端。
3. 后端新增明确的“记录不存在”异常，并在 `GlobalExceptionHandler` 映射为 HTTP 404。
4. 前端 API 客户端保留上游状态码：后端 404 映射为 SvelteKit 404；后端超时或 5xx 返回真实 503，或渲染带 `noindex` 的故障页。
5. 为动态 slug、非法 slug、缺失记录和后端故障增加测试。

验收：

- 任意已发布数据库记录都能通过 `/learning/{slug}` 返回完整 SSR HTML 和 200。
- 不存在的 slug 返回 404；上游不可用返回 503；两者都不能进入 sitemap。
- 首页所有文章链接自动化巡检均为 200，canonical 与当前文章 URL 一致。

### 阶段 C：补齐抓取与归一信号

1. 新增 `frontend/src/routes/robots.txt/+server.ts`，允许抓取公开页面并声明 sitemap 的绝对 HTTPS URL。
2. 新增 `frontend/src/routes/sitemap.xml/+server.ts`：
   - 包含首页、文章聚合页和全部已发布文章。
   - URL 使用规范 HTTPS 地址。
   - `lastmod` 来自真实更新时间，不使用每次请求的当前时间。
   - 草稿、404、故障页和 API 地址不进入 sitemap。
3. 新增共享 SEO 配置模块，例如 `frontend/src/lib/seo/site.ts`，集中管理站名、规范 origin、默认描述、作者和默认分享图。
4. 首页和文章页增加绝对 canonical。
5. 为 robots、sitemap XML、canonical 和错误状态增加 endpoint/SSR 测试。

验收：

- `/robots.txt` 返回 200、`text/plain`，其中 sitemap URL 可访问。
- `/sitemap.xml` 返回 200、合法 XML；每个 URL 都返回 200、存在自 canonical，且集合无重复。
- sitemap 只在文章发布或更新时间变化时改变，不能因普通请求刷新 `lastmod`。

### 阶段 D：完善页面元数据和结构化数据

1. 首页补充 Open Graph、Twitter Card、`WebSite` 和 `Person` JSON-LD；个人信息只写真实可公开信息。
2. 文章页补充 `og:type=article`、发布日期、更新时间、作者、分享图、`TechArticle` 或 `BlogPosting` JSON-LD、`BreadcrumbList` JSON-LD。
3. 增加 favicon、apple touch icon、默认 1200x630 OG 图；文章截图设置明确尺寸和有意义的 `alt`。
4. 将发布日期改为 `<time datetime="YYYY-MM-DD">`，并显示真实更新时间。
5. 数据模型增加 `updatedAt`、`author`、`status`；`seoTitle` 和 `seoDescription` 可选，缺省时从标题和摘要生成。涉及新 Flyway migration、`SiteLearningRecord.java`、响应 DTO 和前端 API 类型。

验收：

- 首页和每篇文章的 title、description、canonical 唯一且与可见内容一致。
- JSON-LD 可被结构化数据校验工具解析，无必填字段错误。
- 分享链接能稳定展示正确标题、描述和 1200x630 图片。
- 草稿无法通过列表、详情接口或 sitemap 被公开访问。

### 阶段 E：建立内容架构和站内链接

1. 新增 `/learning` 文章聚合页，首期不做会产生大量重复 URL 的任意筛选组合。
2. 首页主导航增加指向 `/learning` 的真实页面链接。
3. 文章页增加可见面包屑、同主题相关文章、上一篇/下一篇。
4. 首个主题集群围绕“本地 Kubernetes 与国内网络排障”拆分 6-10 篇原创内容：
   - Minikube 安装与版本选择。
   - Docker 驱动启动失败排查。
   - ImagePullBackOff 定位步骤。
   - 国内镜像代理与 `minikube image load`。
   - Deployment、Service、NodePort 最小实践。
   - Helm 管理 SvelteKit + Spring Boot 部署。
5. 当前 Kubernetes 总教程作为支柱页，与具体问题文章双向内链。
6. 每篇内容发布前检查搜索意图、可复现过程、命令版本、原创截图、相关内链、发布日期和更新时间。

验收：

- `/learning` 可从首页到达，所有文章最多 3 次点击可到达。
- 每篇文章至少有 2 条上下文相关内链，不添加无关链接凑数量。
- 连续 4 周每周发布 1-2 篇高质量文章，完成首个主题集群后再扩展 SvelteKit 或 Spring Boot。
- 不创建正文高度重复、仅关键词不同的页面。

### 阶段 F：性能、平台接入与复盘

1. 域名上线后接入 Google Search Console、Bing Webmaster Tools 和百度搜索资源平台，完成域名验证并提交 sitemap。
2. 采用不泄露敏感数据的统计方案，至少记录自然搜索落地页、来源、页面浏览和站内文章点击。
3. 为 Nginx 增加文本压缩、安全响应头和缓存策略：哈希静态资源长期缓存，SSR HTML 不做不可控长期缓存，sitemap/robots 使用短缓存。
4. 使用 Lighthouse、浏览器性能面板和真实用户数据检查 Core Web Vitals。
5. 每月按 query、page、impressions、clicks、CTR、average position 复盘：高曝光低 CTR 页面调整标题和描述；排名 8-20 页面补充深度和内链；零曝光且重复的内容合并或重写。

验收：

- Lighthouse SEO 分数至少 95，关键页面无严重抓取错误。
- 移动端真实用户数据目标：LCP 不高于 2.5 秒、INP 不高于 200 毫秒、CLS 不高于 0.1，以第 75 百分位评估。
- 站长平台成功读取 sitemap；上线 30 天内无持续服务器错误、重定向链、软 404 或重复 canonical 告警。
- 建立月度 SEO 记录，区分品牌词与非品牌词。

## 5. 数据指标

### 上线基线

- 可索引 URL 数，sitemap 提交、发现、抓取和已索引数量。
- 404、软 404、5xx、重定向链和重复页面数量。
- 首页和文章页 Core Web Vitals。

### 30 天观察

- 品牌词是否能找到规范首页。
- 已发布文章的发现、抓取和索引比例。
- 非品牌 query 数、曝光量、点击量和 CTR。
- 搜索落地页与目标关键词意图是否一致。

### 60-90 天优化

- 按主题集群统计非品牌曝光和点击趋势。
- 优先更新排名 8-20 且有真实曝光的页面。
- 识别同一关键词下互相竞争的页面，合并内容并设置正确重定向。
- 以连续增长趋势和有效索引率为主，不设不可靠的固定流量承诺。

## 6. 测试与验证清单

### 自动化测试

- 前端 SSR：title、description、canonical、OG、JSON-LD、面包屑、`time`。
- Endpoint：robots、sitemap、content-type、绝对 URL、XML 转义、草稿过滤。
- 路由：任意已发布 slug 200、不存在 slug 404、后端故障 503/noindex。
- 后端：列表只返回已发布记录，详情 404，updatedAt/author/status 字段正确。
- 链接巡检：sitemap 和首页文章链接均返回 200，不存在重定向链。

现有前端测试只覆盖正文渲染，见 `frontend/src/routes/page.test.ts:28-43` 和 `frontend/src/routes/learning/kubernetes-minikube/page.test.ts:31-39`；现有后端测试缺少不存在 slug，见 `backend/src/test/java/com/abilityre/site/SiteControllerTest.java:24-53`。

### 发布后检查

```bash
curl -I http://example.com/learning/kubernetes-minikube
curl -I https://example.com/learning/kubernetes-minikube
curl -sS https://example.com/robots.txt
curl -sS https://example.com/sitemap.xml
curl -sS https://example.com/learning/kubernetes-minikube
```

- 检查 HTTP 到 HTTPS 的单次 301。
- 检查 canonical、OG 和 JSON-LD 是否使用规范域名。
- 检查 sitemap 中每个 URL 的状态码和自 canonical。
- 使用结构化数据测试工具验证首页和文章页。
- 在三类站长平台检查抓取、索引和 sitemap 处理结果。

## 7. 风险与缓解

| 风险 | 影响 | 缓解措施 |
| --- | --- | --- |
| 未确定域名就生成 canonical/sitemap | 索引信号反复变化 | 域名和唯一 host 先于 SEO 元数据上线 |
| API 失败仍返回 200 | 故障页被当正文索引 | 区分 404 与 503；故障页 noindex |
| sitemap 每次请求更新 lastmod | 搜索引擎收到噪声 | 使用数据库真实 `updated_at` |
| 新文章仍使用固定前端路由 | 首页出现死链 | 先完成 `[slug]` 动态路由和测试 |
| 只做 meta 不持续产出内容 | 有收录但没有搜索覆盖 | 按主题集群持续发布并月度复盘 |
| 为关键词生产相似页面 | 重复内容和关键词内耗 | 一页解决一个搜索意图，重复主题合并 |
| JSON-LD 与可见内容不一致 | 富结果资格和可信度下降 | 统一由页面数据生成并测试 |

## 8. 推荐落地顺序

1. 确定正式域名、备案、HTTPS 和唯一主站地址。
2. 完成动态文章路由、真实 404/503，消除软 404 和新增文章死链。
3. 上线 robots、动态 sitemap、canonical，并提交站长平台。
4. 完善文章数据模型、OG、JSON-LD、favicon 和分享图。
5. 上线 `/learning` 聚合页、面包屑和相关文章内链。
6. 用 4 周完成首个 Kubernetes 主题集群，之后按数据选择下一个主题。
7. 每月固定复盘索引、query、CTR、排名区间与 Core Web Vitals。
