# Ability Re 构建与部署优化方案

## 目标与现状

目标是在不降低测试覆盖、不改变现有访问地址的前提下，缩短从 push 到部署完成的时间，并让前端、后端可以按改动范围独立构建。

当前流水线的主要成本和约束：

- 后端每次在全新容器中执行 Maven，未持久化本地仓库，见 `.woodpecker/ci.yml:13-17`。
- 前端每次重新执行 `pnpm install`，未持久化 pnpm store，见 `.woodpecker/ci.yml:20-29`。
- `package` 使用 `depends_on` 后，Woodpecker 会让无依赖的 backend/frontend 并行运行；服务器只有 2 CPU、1.8 GiB 内存、无 swap，需要监控并行时的峰值内存。
- 任意 main 分支提交都会完整构建前后端，包括只改文档的提交，见 `.woodpecker/ci.yml:5-7`。
- 当前发布包总是同时包含约 48 MiB 的后端 JAR 和前端静态文件，见 `.woodpecker/ci.yml:31-43`。
- 当前重启命令 `docker compose up -d` 不保证已经运行的后端 Java 进程重新加载新 JAR，见 `DEPLOYMENT_CHECKLIST.md:20`。
- 本机热缓存参考值：前端依赖安装约 1 秒，前端检查/测试/构建约 21 秒；后端测试打包约 12-23 秒。CI 冷缓存耗时需从 Woodpecker 再采集。

## 推荐路线

分两期实施。第一期只改缓存与命令，风险低；第二期拆分前后端工作流，让单侧改动不再构建整个项目。

### 第一期：持久化依赖缓存

1. 在 ECS 创建专用缓存目录：
   - `/opt/woodpecker-cache/maven`
   - `/opt/woodpecker-cache/pnpm`
2. 在 Woodpecker 将该仓库设为 Trusted。Host volume 仅允许 trusted repository 使用，且只应在受控的私有实例中启用。
3. 在 `.woodpecker/ci.yml` 的 backend step 挂载：
   - `/opt/woodpecker-cache/maven:/root/.m2/repository`
4. 在 frontend step 显式设置 pnpm store 并挂载：
   - `/opt/woodpecker-cache/pnpm:/pnpm/store`
   - 执行 `pnpm config set store-dir /pnpm/store`
   - 执行 `pnpm install --frozen-lockfile --prefer-offline`
5. 已将后端命令简化为 `mvn -B -ntp package`。`package` 已包含 test 生命周期，`-ntp` 可减少无用下载进度日志。
6. 保留 backend/frontend 并行执行；连续观察 5 次流水线。如出现 OOM、容器被杀或系统可用内存低于 200 MiB，再改为串行，不能为了几秒并行收益牺牲稳定性。
7. 已从 `frontend/package.json` 删除未使用的 `@sveltejs/adapter-auto`，当前实际使用的是 `adapter-static`，见 `frontend/svelte.config.js:1-10`。

预期收益：第二次及后续构建不再从公网完整下载 Maven 与 pnpm 依赖。以 5 次 warm build 的中位数衡量，完整流水线耗时应降至改造前中位数的 60% 以内。

### 第二期：按改动范围拆分工作流

将当前单文件流水线拆为三个职责明确的工作流：

1. `.woodpecker/backend.yml`
   - 触发路径：`backend/**`、`docker-compose.yml`、该工作流文件。
   - 执行后端测试和打包，仅上传 JAR。
   - 部署后明确执行 `docker compose restart backend`，随后检查后端健康接口。
2. `.woodpecker/frontend.yml`
   - 触发路径：`frontend/**`、`nginx.conf`、该工作流文件。
   - 执行 sync、lint、test、build，仅上传前端静态文件和 nginx 配置。
   - 仅在 nginx 配置变化时重建 frontend 容器；普通静态文件更新不重启 nginx。
3. `.woodpecker/infra.yml`
   - 触发路径：`docker-compose.yml`、部署脚本、基础设施配置。
   - 执行 Compose 配置校验并部署基础设施变更。

Woodpecker 3.16 支持 `when.path.include/exclude`。拆分时不能简单地在现有 backend/frontend step 上加 path 条件，因为当前统一 package step 同时依赖两侧产物；跳过任一侧都会造成打包缺文件。必须同时拆开打包和部署。

预期收益：

- 只改前端时不启动 Maven/Spring 测试。
- 只改后端时不安装 pnpm 依赖、不构建静态页面。
- 只改 `README.md`、`DEPLOYMENT_CHECKLIST.md` 时不部署。
- 单侧改动的 warm build 中位数应不超过当前完整 warm build 中位数的 65%。

### 第三期：部署可靠性与可观测性

1. 后端已增加 Compose healthcheck，目标为容器内访问 `/actuator/health/readiness` 成功，并检查数据库连接。
2. 前端增加 nginx healthcheck，目标为容器内首页返回 HTTP 200。
3. deploy step 上传到临时文件，校验成功后再覆盖正式产物，避免半包部署。
4. 每次部署完成后执行：
   - `curl --fail http://127.0.0.1:18080/api/health`
   - `curl --fail http://127.0.0.1:18081/`
5. 健康检查失败时让流水线失败，并保留上一版产物用于人工回滚。
6. 记录每个 step 的持续时间；后续优化只接受有基准对比的数据，不以单次体感判断。

## 暂不推荐的方案

暂不把前后端改成 CI 构建 Docker 镜像并推送 GHCR/Docker Hub。镜像方案的优点是版本不可变、回滚清晰，但当前机器只有 2 核、1.8 GiB 内存，构建镜像会增加 Docker layer、registry 上传下载和凭据管理成本。当前前端产物仅约 148 KiB，后端 JAR 约 48 MiB，直接按组件上传更简单，也更符合现阶段规模。

满足以下任一条件后再评估镜像化：

- 增加预发布/生产两套环境。
- 需要一键按 commit 回滚。
- 部署节点超过 1 台。
- CI 机器升级到至少 4 CPU、4 GiB 内存，或迁移到独立构建节点。

## 验收标准

- 连续 5 次未改依赖锁文件的构建中，Maven 和 pnpm 均命中持久化缓存。
- 完整 warm build 中位数不超过改造前中位数的 60%。
- 前端单侧提交不会运行 backend workflow。
- 后端单侧提交不会运行 frontend workflow。
- 文档单侧提交不会执行构建或部署。
- 所有现有前端 Vitest、Svelte check、后端 JUnit 测试继续通过。
- 部署成功后，`18080` 健康接口与 `18081` 首页均返回成功；失败时流水线明确失败。
- 后端 JAR 更新后，Java 容器必须重启并运行本次 commit 的产物。
- 缓存目录和 SSH secret 不出现在仓库、不打印到流水线日志。

## 风险与缓解

- **缓存污染**：pnpm 使用 frozen lockfile；Maven 保留版本锁定。出现异常时只清理对应缓存目录，不删除应用数据。
- **Trusted 仓库权限扩大**：仅为当前自管仓库开启，缓存挂载限制在 `/opt/woodpecker-cache`，不挂载宿主机根目录。
- **并行构建内存不足**：监控 5 次峰值；发现 OOM 后串行执行 backend/frontend，或升级 CI 节点。
- **路径过滤漏构建**：`docker-compose.yml`、`nginx.conf` 和 workflow 自身必须纳入对应 include；首次拆分用前端、后端、文档、基础设施四类测试提交验证。
- **部署了新文件但进程未更新**：后端部署必须显式 restart 或 force-recreate，并以健康检查作为完成条件。

## 实施顺序与验证

1. 在 Woodpecker 页面记录当前最近 5 次完整流水线及各 step 耗时，形成基准。部署重建命令已固化在流水线中，不再依赖可缺失的 `deploy_restart_cmd` Secret。
2. 实施第一期缓存，运行 1 次 cold build 和 5 次 warm build，对比中位数及峰值内存。
3. 验证缓存稳定后，拆分 backend/frontend/infra 工作流。
4. 分别提交仅前端、仅后端、仅文档、仅 Compose 的测试变更，确认 path filter 符合预期。
5. 加入健康检查与显式后端重启，验证成功部署和故意失败两条路径。
6. 运行 `docker compose config`、`pnpm lint && pnpm test && pnpm build`、`mvn -B -ntp package` 作为最终质量门槛。

## 参考

- Woodpecker 3.16 workflow syntax：`depends_on` 会启用 DAG 并行；`when.path` 支持按文件变化过滤。
- Woodpecker volumes：host volumes 需要 Trusted repository，且应仅在受控环境使用。
