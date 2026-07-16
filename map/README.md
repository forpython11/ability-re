# 项目公共文件导览

文件说明已经按前后端拆分：

- [前端文件导览](frontend.md)
- [后端文件导览](backend.md)
- [前端架构图](../docs/architecture/frontend.md)
- [后端架构图](../docs/architecture/backend.md)

这份总导览只介绍根目录、公共部署和项目文档。完整目录关系如下：

```text
ability-re/
├── frontend/          SvelteKit 前端页面和 SSR 服务
├── backend/           Spring Boot API 和数据库访问
├── .woodpecker/       前后端 CI 与远程部署流程
├── docs/              架构、方案和文件导览
├── docker-compose.yml 公共容器编排
└── nginx.conf         前后端统一 HTTP 入口
```

## 根目录与公共部署

| 文件 | 作用 | 通常什么时候修改 |
| --- | --- | --- |
| `.env.example` | Compose 环境变量模板，包含 MySQL 密码占位值和前端公开地址 | 新增公共环境变量或部署地址变化时 |
| `.gitignore` | 忽略依赖、构建产物、真实 `.env` 和日志 | 新增不应提交的本地文件时 |
| `.hermes_continuation.md` | 历史 AI 协作上下文，不参与编译和运行 | 通常不需要修改 |
| `AGENTS.md` | 约定提交信息、推送说明、验证习惯和代码注释规范 | 协作规范变化时 |
| `README.md` | 项目首页，包含技术栈、启动方式和文档入口 | 使用方式或文档入口变化时 |
| `DEPLOYMENT_CHECKLIST.md` | 当前线上状态和后续部署检查项 | 服务器状态或部署待办变化时 |
| `LOCAL_K8S_MINIKUBE_SETUP.md` | 本地 Minikube、kubectl 和 Helm 的安装验证记录 | 本地 Kubernetes 环境变化时 |
| `docker-compose.yml` | 编排 MySQL、Spring Boot、SvelteKit Node 和 Nginx | 服务、端口、挂载、环境变量或健康检查变化时 |
| `nginx.conf` | 把 `/api` 转发给后端，其余请求转发给 SvelteKit | HTTP 路由、限流或代理配置变化时 |
| `.woodpecker/known_hosts` | 固定部署服务器 SSH 主机指纹，前后端发布共同使用 | 服务器重装或 SSH 主机密钥变化时 |

## 项目文档

| 文件 | 作用 | 通常什么时候修改 |
| --- | --- | --- |
| `docs/architecture/frontend.md` | 展示浏览器、Nginx、SvelteKit 和后端 API 的关系 | 前端分层或请求链路变化时 |
| `docs/architecture/backend.md` | 展示 Controller、Service、Repository、MySQL 和 Flyway 的关系 | 后端分层或数据流变化时 |
| `docs/plans/build-optimization.md` | 记录构建缓存、工作流拆分和部署可靠性方案 | 构建优化方向变化时 |
| `docs/plans/kubernetes-migration.md` | 记录 Minikube、Helm 和未来云端迁移方案 | Kubernetes 策略变化时 |
| `docs/plans/seo-optimization.md` | 记录域名、HTTPS、sitemap、结构化数据和内容 SEO 方案 | SEO 优先级或实施状态变化时 |
| `map/README.md` | 当前公共文件导览和前后端导览入口 | 公共文件或文档结构变化时 |
| `map/frontend.md` | 逐个介绍前端源码、配置、测试和发布文件 | 前端文件新增、删除或移动时 |
| `map/backend.md` | 逐个介绍后端源码、配置、迁移、测试和发布文件 | 后端文件新增、删除或移动时 |

## 按任务选择入口

| 想做的事情 | 先阅读 |
| --- | --- |
| 修改页面、样式或前端取数 | [前端文件导览](frontend.md) |
| 修改 API、数据库或后端测试 | [后端文件导览](backend.md) |
| 修改容器镜像构建 | 前后端文件导览中的 `Dockerfile`、`.dockerignore` |
| 修改容器连接、端口或公网代理 | `docker-compose.yml`、`nginx.conf` |
| 修改自动部署 | 对应的前端或后端文件导览中的 Woodpecker 部分 |
| 理解完整请求链路 | 前端架构图和后端架构图 |
