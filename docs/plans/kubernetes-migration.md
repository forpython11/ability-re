# Ability Re 本地 Kubernetes 优先方案

## 需求摘要

先在当前 Mac 上建立完整的本地 Kubernetes 开发环境，验证镜像、Helm、Deployment、Service、PVC、健康检查、滚动更新和回滚。当前 ECS Docker Compose 环境继续作为线上服务，不在本地验证阶段迁移生产流量或生产数据。

当前事实：

- Mac 为 Intel `x86_64`、12 CPU、16 GiB RAM，适合运行 4 CPU/6 GiB 的 Minikube。
- 本机尚未安装 Docker、kubectl、Minikube 和 Helm。
- 当前线上后端通过 JAR bind mount 运行，见 `docker-compose.yml:25-42`。
- 当前线上前端通过 nginx 和静态目录 bind mount 运行，见 `docker-compose.yml:44-54`。
- 当前 Woodpecker Agent 位于远端 ECS，见 `.woodpecker/ci.yml:45-87` 的 SSH 部署流程，不适合直接访问家庭网络内的 Minikube API。

## 架构决策

第一阶段采用 Docker Desktop + Minikube + Helm。Minikube 提供真实 Kubernetes API，适合在本机验证应用清单，但不承担公网生产流量。

本地组件：

- Docker Desktop：本地容器运行时。
- Minikube：单节点本地 Kubernetes 集群，分配 4 CPU、6 GiB RAM、30 GB 磁盘；Docker Desktop 分配 8 GiB RAM。
- Helm：管理前端、后端、MySQL 和本地配置。
- Traefik：通过 Helm 安装，验证本地 Ingress 路由。
- 本地 Docker 镜像：通过 `minikube image load` 加载，不依赖 ACR。
- MySQL StatefulSet + PVC：仅保存本地测试数据。
- `kubectl port-forward`：第一条稳定访问路径；Ingress 作为后续验证项。

第二阶段才迁移到阿里云 Kubernetes，并引入 ACR、RDS、Woodpecker CD、域名和 HTTPS。

## 实施阶段

### 阶段 0：固定线上基线

1. 保持 `8.136.60.154:18081` 的 Compose 服务运行。
2. 更新 Woodpecker Compose 重启命令并验证一次自动部署。
3. 本地实验不连接线上 MySQL，不修改线上安全组和域名。

### 阶段 1：本地工具与集群

1. 安装 Docker Desktop，分配 4 CPU 和 8 GiB RAM。
2. 安装 kubectl、Minikube 和 Helm。
3. 使用 Docker driver 创建 4 CPU/6 GiB/30 GB 的 Minikube。
4. 验证 node Ready、集群 DNS 和默认 StorageClass。

### 阶段 2：容器镜像化

1. 新增 `backend/Dockerfile`，使用 Java 21 多阶段构建和非 root runtime。
2. 新增 `frontend/Dockerfile`，使用 Node/pnpm build stage 和 nginx runtime。
3. 新增 `.dockerignore`，排除构建产物、本地依赖和 Secret。
4. 使用当前 Git SHA 构建前后端镜像，避免固定 `local` 标签阻止滚动更新。
5. 将镜像加载进 Minikube，本地 values 使用相同 SHA 和 `imagePullPolicy: IfNotPresent`。

### 阶段 3：Helm Chart

1. 创建 `deploy/helm/ability-re`。
2. 创建 MySQL StatefulSet、Service 和 PVC。
3. 创建 frontend/backend Deployment 和 ClusterIP Service；后端 Service 固定命名为 `backend`，保持 `nginx.conf` 的 DNS 契约。
4. 后端 liveness/readiness 分别使用 Actuator 的 `/actuator/health/liveness` 和 `/actuator/health/readiness`，readiness 包含数据库检查。
5. 配置 requests/limits、ConfigMap，并通过预创建的 `ability-re-secrets` 引用敏感值。
6. 提供 `values-local.yaml` 和 `values-prod.yaml`，隔离本地与未来云端差异。
7. 通过 Helm lint、template 和 kubectl dry-run。

### 阶段 4：本地部署与验证

1. 使用 Helm 安装到 `ability-re` Namespace。
2. 等待三个工作负载 Ready，确认 PVC Bound。
3. 使用 port-forward 验证首页、健康接口和联系表单。
4. 删除前后端 Pod，验证 Deployment 自愈。
5. 执行 Helm upgrade 和 rollback。
6. stop/start Minikube，验证 PVC 数据保留。
7. 最后安装 Traefik，启用 Ingress 并验证本地域名路由。

### 阶段 5：CI 边界

1. Woodpecker 继续运行现有测试和 Compose 部署。
2. 不把本地 kubeconfig 或 Minikube API 暴露给公网 Woodpecker。
3. 本地部署使用手工 Helm 命令或仓库内不含 Secret 的本地脚本。
4. 云端集群建立后，再把镜像推送和 Helm upgrade 接入 Woodpecker。

### 阶段 6：未来云端迁移

1. 选择 ACK 或独立 kubeadm 集群。
2. 使用 ACR 保存 commit SHA 镜像。
3. 使用 RDS MySQL 并完成备份恢复演练。
4. 使用同一 Helm Chart 的 `values-prod.yaml` 部署。
5. 为 Woodpecker 配置 Namespace 最小权限 RBAC。
6. 验证测试域名、HTTPS、自动回滚后再切生产流量。

## 验收标准

- Minikube node 为 Ready，默认 StorageClass 可动态创建 PVC。
- frontend、backend、MySQL 均 Ready，30 分钟内无异常重启。
- 首页、`/api/health` 和联系表单端到端成功。
- Minikube stop/start 后测试数据仍存在。
- 删除前端或后端 Pod 后，5 分钟内恢复 Ready。
- Helm lint、template、dry-run、upgrade 和 rollback 全部成功。
- 本地配置不连接线上数据库，不影响线上 Compose 服务。
- Git 中不存在真实密码、私钥、kubeconfig 或本地 Secret。

## 风险与缓解

- **Mac 资源竞争**：限制 Minikube 为 4 CPU/6 GiB；不用时执行 `minikube stop`。
- **镜像拉取失败**：本地镜像使用 `minikube image load`、Git SHA 和 `IfNotPresent`，不依赖公网 Registry。
- **数据误删**：本地只使用测试数据；`minikube delete` 前明确确认不需要 PVC 数据。
- **误连生产库**：`values-local.yaml` 使用独立 Secret 和集群内 MySQL Service，不接受线上 JDBC 默认值。
- **远端 CI 暴露本机**：本地阶段不上传 kubeconfig、不开放 Kubernetes API、不让 Woodpecker 部署 Minikube。
- **代理出现 502**：Helm 后端 Service 名固定为 `backend`，并用端到端 `/api/health` 验证 nginx 到后端的 DNS 与端口契约。
- **本地与云端差异**：所有环境差异集中在 values 文件，模板保持一致，并在云端切流量前重新执行完整验收。

## 验证命令

```bash
minikube status
kubectl get nodes
kubectl -n ability-re get pods,svc,pvc
helm lint deploy/helm/ability-re -f deploy/helm/ability-re/values-local.yaml
helm history ability-re -n ability-re
curl --fail http://127.0.0.1:18081/
curl --fail http://127.0.0.1:18081/api/health
```

## 参考

- [Minikube start](https://minikube.sigs.k8s.io/docs/start/)：最低 2 CPU、2 GB 可用内存、20 GB 磁盘。
- [kind quick start](https://kind.sigs.k8s.io/docs/user/quick-start/)：kind 和 Minikube 都提供真实 Kubernetes；本项目选择 Minikube 是因为单节点、存储和本地服务访问流程更直接。
- 本地集群用于开发和验证，不替代需要公网稳定性、高可用和备份能力的生产集群。
