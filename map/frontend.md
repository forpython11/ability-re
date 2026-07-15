# 前端文件导览

前端使用 SvelteKit 2、Svelte 5 和 TypeScript，通过 adapter-node 输出可运行的 SSR 服务。建议先看[前端架构图](../docs/architecture/frontend.md)，再按本页顺序阅读文件。

## 前端 CI 与发布

| 文件 | 作用 | 通常什么时候修改 |
| --- | --- | --- |
| `.woodpecker/frontend.yml` | 手动执行前端依赖安装、类型检查、测试、SSR 构建、打包和上传 | 前端构建命令、发布包或 Secret 变化时 |
| `.woodpecker/deploy-frontend.sh` | 在服务器校验并原子替换前端产物，重建 Node/Nginx 后验证首页 | 前端服务器部署步骤变化时 |

公共 SSH 指纹、Compose 和 Nginx 说明见[项目公共文件导览](README.md)。

## 构建与环境配置

| 文件 | 作用 | 通常什么时候修改 |
| --- | --- | --- |
| `frontend/.env.example` | 前端服务端环境变量模板，指定内部后端 API 地址 | 后端地址或环境变量名变化时 |
| `frontend/package.json` | 定义依赖和 `dev`、`lint`、`test`、`build` 命令 | 增删依赖或 npm 脚本时 |
| `frontend/pnpm-lock.yaml` | 锁定依赖的精确版本，保证本地和 CI 安装一致 | `pnpm install` 更新依赖时自动变化，不手工编辑 |
| `frontend/svelte.config.js` | 配置 Svelte 预处理和 adapter-node SSR 输出 | 更换适配器或预处理方式时 |
| `frontend/tsconfig.json` | TypeScript 严格检查和模块解析配置 | 调整 TypeScript 编译规则时 |
| `frontend/vite.config.ts` | 配置 SvelteKit Vite 插件和 Vitest 的 jsdom 环境 | 调整构建、路径解析或测试环境时 |

## 应用入口与公共样式

| 文件 | 作用 | 通常什么时候修改 |
| --- | --- | --- |
| `frontend/src/app.html` | 最外层 HTML 模板，接收每页 head 和 SSR 正文 | 修改 `html` 属性、全局 meta 或 body 外壳时 |
| `frontend/src/app.d.ts` | 引入 SvelteKit 自动生成的 TypeScript 类型 | 扩展全局 App 类型时；通常不修改 |
| `frontend/src/app.css` | 导航、首页、卡片、文章、代码块和移动端布局的全站样式 | 修改视觉或响应式布局时 |
| `frontend/src/test-setup.ts` | 给 Vitest 加载 DOM 专用断言 | 增加所有前端测试共用的初始化时 |
| `frontend/src/routes/+layout.svelte` | 根布局，加载全站 CSS 并渲染当前路由页面 | 增加全站导航、页脚或公共 Provider 时 |

## API 与数据类型

| 文件 | 作用 | 通常什么时候修改 |
| --- | --- | --- |
| `frontend/src/lib/api/types.ts` | 定义首页、文章和统一 API 响应类型，与后端 DTO 对齐 | 后端响应字段变化时同步修改 |
| `frontend/src/lib/api/server.ts` | 在 SvelteKit 服务端请求 Spring Boot、检查状态并解包 `data` | 新增读取接口或修改统一请求逻辑时 |
| `frontend/src/lib/api/client.ts` | 浏览器侧保护入口，禁止直接调用内部后端地址 | 改变“后端只由 SSR 服务访问”的边界时 |
| `frontend/src/lib/site/fallback.ts` | 后端不可用时使用的首页静态兜底内容 | 修改兜底文字或增加离线内容时 |

## 首页路由

| 文件 | 作用 | 通常什么时候修改 |
| --- | --- | --- |
| `frontend/src/routes/+page.server.ts` | 首页服务端加载器：读取后端，失败时切换到兜底内容 | 修改首页取数或失败策略时 |
| `frontend/src/routes/+page.svelte` | 首页 UI：Hero、学习方向、文章入口、关于和备案说明 | 修改首页结构、文字或交互时 |
| `frontend/src/routes/page.test.ts` | 验证首页关键标题、卡片和文章链接 | 首页可见行为变化时 |

## 学习记录路由

| 文件 | 作用 | 通常什么时候修改 |
| --- | --- | --- |
| `frontend/src/routes/learning/kubernetes-minikube/+page.server.ts` | 固定文章的数据加载器，目前使用写死的 `kubernetes-minikube` slug | 修改文章取数或升级为动态 `[slug]` 时 |
| `frontend/src/routes/learning/kubernetes-minikube/+page.svelte` | 把文章元信息和数据库正文块渲染为段落、代码块 | 修改文章布局或正文渲染时 |
| `frontend/src/routes/learning/kubernetes-minikube/page.test.ts` | 验证文章标题、摘要、正文和代码示例 | 文章页可见行为变化时 |

## 前端一次请求的阅读路线

1. `frontend/src/app.html` 提供 HTML 外壳。
2. `frontend/src/routes/+layout.svelte` 加载全站样式。
3. `frontend/src/routes/+page.server.ts` 在服务端获取首页数据。
4. `frontend/src/lib/api/server.ts` 请求 Spring Boot 并解包响应。
5. `frontend/src/routes/+page.svelte` 使用数据生成首页 HTML。
6. `frontend/src/app.css` 决定页面布局和视觉。

## 常见前端任务

| 想做的事情 | 先修改 | 通常还会修改 |
| --- | --- | --- |
| 改首页文字或结构 | `frontend/src/routes/+page.svelte` | 首页测试、数据库内容 |
| 改全站视觉 | `frontend/src/app.css` | 对应 `.svelte` 页面 |
| 增加后端返回字段 | `frontend/src/lib/api/types.ts` | server load 和页面组件 |
| 增加一个页面 | `frontend/src/routes/` 下的新路由 | 样式和页面测试 |
| 增加一篇文章入口 | 动态文章路由 | 后端文章数据和首页列表 |
| 修改前端部署 | `.woodpecker/frontend.yml` | `deploy-frontend.sh`、Compose、Nginx |

## 推荐阅读顺序

`app.html` -> `+layout.svelte` -> `+page.server.ts` -> `lib/api/server.ts` -> `lib/api/types.ts` -> `+page.svelte` -> `app.css` -> 页面测试
