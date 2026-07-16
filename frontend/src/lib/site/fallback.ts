import type { HomePage, LearningRecord } from '$lib/api/types';

// 后端暂时不可用时，首页仍可用这份静态内容完成 SSR，而不是显示空白页。
export const fallbackHomePage: HomePage = {
  hero: {
    title: '能力重构个人技术记录',
    subtitle: '这里记录个人在 SvelteKit、Spring Boot、MySQL 和服务器部署中的学习过程与项目实践。',
  },
  features: [
    {
      title: '前端学习笔记',
      description: '整理 SvelteKit、TypeScript、页面结构和交互体验相关的学习记录。',
      icon: 'layers',
    },
    {
      title: '后端工程实践',
      description: '记录 Spring Boot、接口设计、参数校验和自动化测试的实践过程。',
      icon: 'database',
    },
    {
      title: '部署与 Kubernetes 记录',
      description: '沉淀 Linux、Docker、Minikube、Kubernetes、MySQL、Flyway 和日常部署排查经验。',
      icon: 'sparkles',
    },
  ],
  learningRecords: [
    {
      slug: 'kubernetes-minikube',
      title: '从零跑通部署入口：Minikube、Nginx 反向代理、域名解析与备案排查',
      summary:
        '把本机 Kubernetes 工具链、线上 Docker Compose、域名解析、Nginx 反向代理和个人备案限制串起来，记录每一步的结果和排查过程。',
      category: 'Kubernetes learning record',
    },
  ],
};

// 预留的文章兜底集合，以 slug 为键可以快速找到对应文章。
export const fallbackLearningRecords: Record<string, LearningRecord> = {
  'kubernetes-minikube': {
    slug: 'kubernetes-minikube',
    title: '从零跑通部署入口：Minikube、Nginx 反向代理、域名解析与备案排查',
    summary:
      '这是一篇真实学习记录：目标不是背概念，而是把本机 Kubernetes 工具链、线上 Docker Compose、域名解析、Nginx 反向代理和个人备案限制串起来。',
    category: 'Kubernetes learning record',
    environment:
      'macOS Intel / Docker Desktop / Minikube v1.38.1 / Kubernetes v1.30.5 / Alibaba Cloud Linux 3 / Nginx 1.24.0',
    publishedAt: '2026-07-14',
    blocks: [
      {
        type: 'section',
        heading: '我到底做了什么',
        body: '这次实践完成的是一条最小但完整的 Kubernetes 本地部署链路：先准备本机容器运行环境，再启动一个单节点 Kubernetes 集群，然后把一个 Nginx 容器以 Deployment 的形式运行起来，并通过 Service 暴露成本机可以访问的地址。\n\nkubectl 是操作 Kubernetes 的命令行工具；Minikube 是本机单节点 Kubernetes 集群；Helm 是后续把一组 Kubernetes YAML 打包成可重复安装应用的包管理工具。',
        codeSample: null,
      },
      {
        type: 'result',
        heading: '最终跑通的结果',
        body: '本地 Minikube 集群已经正常运行，Nginx 测试 Pod 已达到 1/1 Running。这说明 Kubernetes 集群、Pod 调度、镜像加载、Service 暴露和本机访问都已经打通。',
        codeSample:
          'minikube status\nhost: Running\nkubelet: Running\napiserver: Running\nkubeconfig: Configured\n\nkubectl get pods\nnginx-86bffb8c6b-z4sc7   1/1   Running   0   26s\n\nminikube service nginx --url\nhttp://127.0.0.1:52969',
      },
      {
        type: 'step',
        heading: '安装命令行工具',
        body: '一开始尝试用 Homebrew 安装 kubectl，但 Homebrew 需要从 GitHub Container Registry 下载 bottle，国内网络很慢。后来改成直接下载 macOS Intel 的二进制文件，分别安装 kubectl、Minikube 和 Helm。',
        codeSample: null,
      },
      {
        type: 'step',
        heading: '启动 Minikube 集群',
        body: 'Minikube 使用 Docker 驱动时，本质上是在 Docker Desktop 里创建一个 Kubernetes 节点容器。最终稳定启动命令是固定 Kubernetes 版本，不额外指定国内 Kubernetes release 镜像源。',
        codeSample: 'minikube start \\\n  --driver=docker \\\n  --kubernetes-version=v1.30.5',
      },
      {
        type: 'step',
        heading: '创建 Nginx Deployment 和 Service',
        body: 'Deployment 负责声明“我要运行一个 Nginx 应用”；Service 负责给这个应用一个稳定入口。',
        codeSample:
          'kubectl create deployment nginx --image=docker.m.daocloud.io/library/nginx:alpine\nkubectl expose deployment nginx --type=NodePort --port=80',
      },
      {
        type: 'problem',
        heading: '这次真正学到的排查经验',
        body: 'Homebrew 下载慢：brew install kubectl 长时间卡在下载 bottle，根因是访问 ghcr.io 慢，处理方式是绕过 Homebrew，直接下载官方二进制文件。\n\n错误页面被当成可执行文件：国内镜像地址下载到 HTML/XML 错误页，经验是下载命令加 curl -fL，让 HTTP 错误直接失败。\n\n阿里云 OSS sha256 404：使用 --image-mirror-country=cn 或特定 --image-repository 时，Minikube 会访问缺失 .sha256 文件的 Kubernetes release 路径。\n\nImagePullBackOff 不是应用坏了：Nginx Pod 出现 ErrImagePull / ImagePullBackOff，根因是 Docker Hub 超时，解决方式是使用国内代理镜像并通过 minikube image load 导入集群。',
        codeSample: null,
      },
      {
        type: 'capability',
        heading: '我现在具备的能力',
        body: '能解释 kubectl、Minikube、Helm 在 Kubernetes 工作流里的职责边界。\n能在 macOS 本机启动 Minikube Kubernetes 集群，并用 kubectl 查看 Node、Pod、Service。\n能根据 Pod 状态区分是调度问题、容器创建问题，还是镜像拉取问题。\n能使用 Deployment 和 Service 部署一个最小可访问应用。\n能把网络和镜像源问题记录成可复用的排查步骤，而不是停留在“命令跑不通”。',
        codeSample: null,
      },
      {
        type: 'next',
        heading: '下一步',
        body: '前后端 Dockerfile、非 root 运行和本地镜像构建验证已经完成。下一步使用当前 Git SHA 重新构建镜像并加载到 Minikube，再创建 Helm Chart 管理 MySQL、Spring Boot 后端、SvelteKit SSR、Nginx 网关、Secret、ConfigMap、Service 和 PVC。',
        codeSample: null,
      },
    ],
  },
};
