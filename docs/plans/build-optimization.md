# Ability Re 构建与部署优化方案

## 目标与现状

目标是在不降低测试覆盖、不改变现有访问地址的前提下，缩短手动发布耗时，并让前端、后端可以独立构建和部署。

当前流水线的主要成本和约束：

- 前后端已拆成 `.woodpecker/backend.yml` 和 `.woodpecker/frontend.yml` 两条手动工作流，通过 `COMPONENT` 选择单个组件，不会因普通 push 自动部署。
- 后端每次在全新容器中执行 Maven，并主动清理临时本地仓库；前端每次执行 frozen lockfile 安装，目前都没有跨流水线持久缓存。
- 两条部署工作流共享 `ability-re-deploy` 并发组，同一时间只发布一个组件，避免 2 CPU、约 1.8 GiB ECS 并发耗尽资源。
- 后端和前端分别生成独立发布包，不再把两侧产物打进同一个压缩包。
- 部署脚本使用 `docker compose up -d --force-recreate` 重建对应容器，并以健康检查作为成功条件。
- 本机热缓存参考值：前端依赖安装约 1 秒，前端检查/测试/构建约 21 秒；后端测试打包约 12-23 秒。CI 冷缓存耗时需从 Woodpecker 再采集。

## 推荐路线

前后端工作流拆分、资源限制、原子替换和健康检查已经完成。剩余优化重点是是否为自管 Woodpecker Agent 引入受控的依赖持久缓存。

### 第一期：持久化依赖缓存

1. 在 ECS 创建专用缓存目录：
   - `/opt/woodpecker-cache/maven`
   - `/opt/woodpecker-cache/pnpm`
2. 在 Woodpecker 将该仓库设为 Trusted。Host volume 仅允许 trusted repository 使用，且只应在受控的私有实例中启用。
3. 在 `.woodpecker/backend.yml` 的 build step 挂载：
   - `/opt/woodpecker-cache/maven:/root/.m2/repository`
4. 在 frontend step 显式设置 pnpm store 并挂载：
   - `/opt/woodpecker-cache/pnpm:/pnpm/store`
   - 执行 `pnpm config set store-dir /pnpm/store`
   - 执行 `pnpm install --frozen-lockfile --prefer-offline`
5. 后端先执行 `mvn test`，再复用编译结果执行 `mvn -DskipTests package`；测试只运行一次，`-ntp` 用于减少无用下载进度日志。
6. backend/frontend 并行构建曾让服务器可用内存降至 82 MiB，并导致流水线被终止，因此已改为串行执行，同时限制 Maven 和 Node 最大堆内存。只有迁移到更大的独立 Agent 后才重新评估并行。
7. 前端当前实际使用 `adapter-node` 生成 SSR 服务，见 `frontend/svelte.config.js`；不能按纯静态站点缓存或部署。

预期收益：第二次及后续构建不再从公网完整下载 Maven 与 pnpm 依赖。以 5 次 warm build 的中位数衡量，完整流水线耗时应降至改造前中位数的 60% 以内。

### 第二期：按组件拆分工作流（已完成）

当前使用两个职责明确的手动工作流：

1. `.woodpecker/backend.yml`：`COMPONENT=backend` 时执行测试、打包 JAR、上传并重建后端容器。
2. `.woodpecker/frontend.yml`：`COMPONENT=frontend` 时执行 sync、lint、test、SSR build、上传并重建 frontend-app/Nginx 容器。

两条工作流都只响应 `main` 分支的 manual 事件，因此文档 push 不会自动部署。Compose 或 Nginx 配置发生变化时，需要根据受影响组件手动运行对应工作流。

### 第三期：部署可靠性与可观测性

1. 后端已增加 Compose healthcheck，容器内访问 `/actuator/health/readiness` 并检查数据库连接。
2. SvelteKit SSR 和 Nginx 均已增加首页 healthcheck。
3. deploy step 已先上传到临时文件，校验成功后再原子替换正式产物，避免半包部署。
4. 每次部署完成后执行：
   - `curl --fail http://127.0.0.1:18080/api/health`
   - `curl --fail http://127.0.0.1:18081/`
5. 健康检查失败时让流水线失败，并保留上一版产物用于人工回滚。
6. 记录每个 step 的持续时间；后续优化只接受有基准对比的数据，不以单次体感判断。

## 本地镜像与线上发布边界

仓库已新增前后端 Dockerfile，供本地 Minikube 构建不可变镜像；现有 Woodpecker 仍上传 JAR 和 SSR build 目录到线上 Compose，不在 2 核、约 1.8 GiB Agent 上构建或推送业务镜像。未来建立 ACK/ACR 后，再把镜像构建和 Helm upgrade 接入 CI。

满足以下任一条件后再评估线上镜像发布：

- 增加预发布/生产两套环境。
- 需要一键按 commit 回滚。
- 部署节点超过 1 台。
- CI 机器升级到至少 4 CPU、4 GiB 内存，或迁移到独立构建节点。

## 验收标准

- 连续 5 次未改依赖锁文件的构建中，Maven 和 pnpm 均命中持久化缓存。
- 完整 warm build 中位数不超过改造前中位数的 60%。
- 手动选择 `COMPONENT=frontend` 时不会运行 backend workflow。
- 手动选择 `COMPONENT=backend` 时不会运行 frontend workflow。
- 普通 push 和文档提交不会自动执行部署。
- 所有现有前端 Vitest、Svelte check、后端 JUnit 测试继续通过。
- 部署成功后，`18080` 健康接口与 `18081` 首页均返回成功；失败时流水线明确失败。
- 后端 JAR 更新后，Java 容器必须重启并运行本次 commit 的产物。
- 缓存目录和 SSH secret 不出现在仓库、不打印到流水线日志。

## 风险与缓解

- **缓存污染**：pnpm 使用 frozen lockfile；Maven 保留版本锁定。出现异常时只清理对应缓存目录，不删除应用数据。
- **Trusted 仓库权限扩大**：仅为当前自管仓库开启，缓存挂载限制在 `/opt/woodpecker-cache`，不挂载宿主机根目录。
- **构建内存不足**：已串行执行 backend/frontend，并限制 JVM/Node 堆；服务器增加 swap 作为保护，长期仍建议升级或拆分 CI 节点。
- **手动组件选错**：运行流水线前核对 `COMPONENT`，Compose 或 Nginx 变更要选择所有受影响组件并分别验证。
- **部署了新文件但进程未更新**：后端部署必须显式 restart 或 force-recreate，并以健康检查作为完成条件。

## 实施顺序与验证

1. 在 Woodpecker 页面记录当前最近 5 次完整流水线及各 step 耗时，形成基准。部署重建命令已固化在流水线中，不再依赖可缺失的 `deploy_restart_cmd` Secret。
2. 如启用持久缓存，运行 1 次 cold build 和 5 次 warm build，对比中位数及峰值内存。
3. 分别手动运行 backend、frontend 工作流，确认只构建和部署所选组件。
4. 验证成功部署和故意失败两条路径，确认健康检查失败会让流水线失败。
5. 运行 `docker compose config`、`pnpm lint && pnpm test && pnpm build`、`mvn -B -ntp package` 作为最终质量门槛。

## 参考

- Woodpecker 3.16 workflow syntax：`depends_on` 会启用 DAG 并行；`when.path` 支持按文件变化过滤。
- Woodpecker volumes：host volumes 需要 Trusted repository，且应仅在受控环境使用。
