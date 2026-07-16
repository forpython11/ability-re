# 默认使用 Node.js 22；需要镜像代理时可通过 --build-arg NODE_IMAGE=... 覆盖。
ARG NODE_IMAGE=node:22-alpine

# 第一阶段安装锁定版本的依赖，并生成 adapter-node 所需的 SSR 构建目录。
FROM ${NODE_IMAGE} AS build

# Corepack 会按照 package.json 中固定的 pnpm 版本安装依赖，避免本机版本差异。
ENV PNPM_HOME=/pnpm
ENV PATH=$PNPM_HOME:$PATH

WORKDIR /workspace

RUN corepack enable

# 先安装依赖以利用 Docker 分层缓存，页面源码变化不会重复解析依赖。
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .
# sync 先生成 SvelteKit 路由类型，再执行 Node SSR 生产构建。
RUN pnpm exec svelte-kit sync \
    && pnpm build

# 第二阶段只复制 SSR 运行产物，不携带源码、pnpm 和开发依赖。
FROM ${NODE_IMAGE} AS runtime

# adapter-node 在运行时读取这些变量，并监听所有容器网络接口的 3000 端口。
ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000

WORKDIR /app

COPY --from=build --chown=node:node /workspace/build ./build

# Node 官方镜像内置 node 非 root 用户，用它启动 SSR 服务。
USER node

# 实际集群入口由 Kubernetes Service 和网关提供，不直接向公网暴露此端口。
EXPOSE 3000

CMD ["node", "build/index.js"]
