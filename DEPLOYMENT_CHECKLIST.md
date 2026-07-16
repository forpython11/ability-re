# Ability Re 部署与本地 Kubernetes 清单

> 当前线上环境：Docker Compose 已部署到 `http://8.136.60.154:18081`，并通过宿主机 Nginx 将 `http://study.cinney.top/` 反向代理到 `127.0.0.1:18081`。
> 当前目标：线上继续使用 Docker Compose；Mac 本地使用 Minikube 和 Helm 学习 Kubernetes，两套环境互不影响。
> 服务器边界：现有 ECS 只有约 2 GiB 内存，不安装 kubeadm、kubelet、Minikube 或其他 Kubernetes 组件，也不承载 Kubernetes 控制面。
> 可选远期方向：只有未来单独购买 ACK 或准备新的高配置集群资源时，才重新评估生产 Kubernetes；这不属于当前待办。
> Kubernetes 当前进度：Minikube 节点 Ready，Nginx 冒烟资源已清理；前后端 Dockerfile 和本地镜像构建验证已完成，下一步是按当前 Git SHA 重建镜像、加载 Minikube 并创建 Helm Chart。

## 1. 保持当前线上环境可用

- [x] Woodpecker 可以从 GitHub 拉取代码
- [x] 前后端构建与测试成功
- [x] `ability-re-mysql`、`ability-re-backend`、`ability-re-frontend-app`、`ability-re-frontend` 已启动
- [x] `http://127.0.0.1:18081/api/health` 返回 `status: ok`
- [x] 公网可以访问 `http://8.136.60.154:18081`
- [x] `study.cinney.top` 已解析到 `8.136.60.154`
- [x] 服务器已安装并启动 Nginx `1.24.0`
- [x] Nginx 已将 `http://study.cinney.top/` 反向代理到 `http://127.0.0.1:18081/`
- [x] 服务器内网验证 `curl -I http://127.0.0.1:18081/` 返回 `200 OK`
- [x] 服务器和公网验证 `curl -I http://study.cinney.top/` 返回 `200 OK`
- [ ] 备案提交前按管局要求暂停 `cinney.top`、`www.cinney.top` 域名解析
- [ ] 等待个人 ICP 备案审核通过
- [ ] 备案通过后重新执行 `certbot --nginx -d study.cinney.top` 签发 HTTPS 证书
- [x] 在服务器创建 `/opt/ability-re/.env`，并将权限设置为 `600`
- [x] 已轮换 MySQL root 和业务用户密码，并同步写入 `.env`
- [ ] 确认服务器上的 `3306`、`18080` 只监听 `127.0.0.1`
- [x] 流水线已固化 Compose 重建命令，不再依赖 `deploy_restart_cmd` Secret
- [x] 前后端已改为串行构建，并限制 Maven/Node 内存，避免 2 GB ECS 资源耗尽
- [x] 明确现有 2 GB ECS 只运行 Docker Compose，不安装 Kubernetes
- [ ] 分别手动运行前后端 Woodpecker 流水线，确认线上 Compose 可以完整更新

本地 Kubernetes 建设期间不关闭、不修改线上 Docker Compose，也不向现有 ECS 安装任何 Kubernetes 组件。公网入口当前包括前端调试端口 `18081` 和 Nginx `80`；后端 `18080` 和 MySQL `3306` 不开放。由于杭州 ECS 未备案域名访问会被阿里云返回 `Non-compliance ICP Filing` 的 403 页面，Let's Encrypt HTTP-01 校验暂时不能通过，HTTPS 配置需要等备案通过后再继续。

### 生产数据库密码轮换

以下步骤会重启后端，应在维护窗口执行。密码只保存在当前 shell 变量和服务器 `.env`，不会写入 Git。

```bash
cd /opt/ability-re
umask 077

read -r -s -p "Current MySQL root password: " CURRENT_ROOT_PASSWORD
echo
NEW_DB_PASSWORD=$(openssl rand -base64 36)
NEW_ROOT_PASSWORD=$(openssl rand -base64 36)

printf "ALTER USER 'ability_re'@'%%' IDENTIFIED BY '%s';\nALTER USER 'root'@'localhost' IDENTIFIED BY '%s';\n" \
  "$NEW_DB_PASSWORD" "$NEW_ROOT_PASSWORD" \
  | docker exec -i -e MYSQL_PWD="$CURRENT_ROOT_PASSWORD" ability-re-mysql mysql -uroot

printf 'MYSQL_PASSWORD=%s\nMYSQL_ROOT_PASSWORD=%s\n' \
  "$NEW_DB_PASSWORD" "$NEW_ROOT_PASSWORD" > .env
chmod 600 .env

docker compose up -d --no-deps --force-recreate backend frontend-app frontend
curl --fail --retry 12 --retry-delay 5 --retry-connrefused http://127.0.0.1:18081/api/health

unset CURRENT_ROOT_PASSWORD NEW_DB_PASSWORD NEW_ROOT_PASSWORD
```

轮换完成后执行 `ss -lntp | grep -E ':(3306|18080|18081)'`，确认只有 `18081` 监听公网地址。

## 2. 安装本地 Kubernetes 工具

当前 Mac 为 Intel `x86_64`，Docker Desktop、kubectl、Minikube 和 Helm 已安装；本地 Minikube 集群已使用 Docker 驱动启动并完成 Nginx 冒烟验证。

- [x] 安装并启动 Docker Desktop
- [ ] Docker Desktop 分配 8 GiB 内存和 4 CPU，为 6 GiB Minikube 留出运行时余量
- [x] 安装 kubectl、Minikube、Helm：

```bash
# Homebrew 访问 ghcr.io 较慢，本机改用二进制方式安装；完整记录见：
# LOCAL_K8S_MINIKUBE_SETUP.md
kubectl version --client
minikube version
helm version
```

- [x] 验证工具：

```bash
docker version
kubectl version --client
minikube version
helm version
```

- [x] 创建本地 Kubernetes 集群：

```bash
minikube start \
  --driver=docker \
  --kubernetes-version=v1.30.5
```

- [x] 验证节点 Ready：

```bash
kubectl get nodes
minikube status
```

- [x] 使用 Nginx 完成本地 Kubernetes 冒烟验证：

```bash
docker pull docker.m.daocloud.io/library/nginx:alpine
minikube image load docker.m.daocloud.io/library/nginx:alpine
kubectl create deployment nginx --image=docker.m.daocloud.io/library/nginx:alpine
kubectl expose deployment nginx --type=NodePort --port=80
kubectl get pods
minikube service nginx --url
```

当前验证结果：`nginx` Pod 曾达到 `1/1 Running`，`minikube service nginx --url` 成功输出本地访问地址；冒烟完成后已删除 Nginx Deployment 和 Service，默认命名空间只保留 Kubernetes 内置 Service。

注意：本机启动 Minikube 时不要加 `--image-mirror-country=cn` 或 `--image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers`，否则会触发阿里云 OSS Kubernetes release `.sha256` 文件 404。Docker Hub 拉业务镜像可能超时，测试镜像优先使用国内代理并通过 `minikube image load` 导入。

## 3. 应用镜像化

- [x] 新增 `backend/Dockerfile`
- [x] 后端使用 Java 21 多阶段构建，运行阶段只包含 JRE
- [x] 后端容器使用非 root 用户 `abilityre`
- [x] 新增 `frontend/Dockerfile`
- [x] 前端使用 Node 22 + pnpm 构建，并通过 Node 非 root 用户运行 adapter-node SSR
- [x] 新增前后端 `.dockerignore`，排除 `.git`、`node_modules`、`target`、`build`、`.env` 和本地缓存
- [x] 验证前后端镜像可以成功构建；后端镜像构建执行 8 个测试，前端镜像首页返回 HTTP 200
- [ ] 使用当前 Git SHA 重新构建待部署镜像：

```bash
TAG=$(git rev-parse --short HEAD)
docker build -t "ability-re-backend:$TAG" backend
docker build -t "ability-re-frontend:$TAG" frontend
```

Docker Hub 在当前网络下超时时，可以通过 Dockerfile 已提供的构建参数改用镜像代理，不把代理地址写死在镜像定义中：

```bash
docker build \
  --build-arg MAVEN_IMAGE=docker.1panel.live/library/maven:3.9.9-eclipse-temurin-21 \
  --build-arg JRE_IMAGE=docker.1panel.live/library/eclipse-temurin:21-jre-alpine \
  -t "ability-re-backend:$TAG" backend
docker build \
  --build-arg NODE_IMAGE=docker.1panel.live/library/node:22-alpine \
  -t "ability-re-frontend:$TAG" frontend
```

- [ ] 将镜像加载进 Minikube：

```bash
TAG=$(git rev-parse --short HEAD)
minikube image load "ability-re-backend:$TAG"
minikube image load "ability-re-frontend:$TAG"
minikube image ls | grep ability-re
```

本地阶段不需要 ACR。Helm 使用相同 Git SHA 标签，并设置 `imagePullPolicy: IfNotPresent`。每个提交的 Pod template 都会变化，因此可以正常触发滚动更新。

## 4. 创建 Helm Chart

计划新增：

```text
deploy/
└── helm/
    └── ability-re/
        ├── Chart.yaml
        ├── values.yaml
        ├── values-local.yaml
        ├── values-prod.yaml
        └── templates/
            ├── namespace.yaml
            ├── mysql-statefulset.yaml
            ├── mysql-service.yaml
            ├── mysql-pvc.yaml
            ├── backend-deployment.yaml
            ├── backend-service.yaml
            ├── frontend-app-deployment.yaml
            ├── frontend-app-service.yaml
            ├── gateway-deployment.yaml
            ├── gateway-service.yaml
            ├── nginx-configmap.yaml
            ├── ingress.yaml
            ├── configmap.yaml
            └── secret.example.yaml
```

- [ ] 创建 Namespace：`ability-re`
- [ ] MySQL 使用 StatefulSet、ClusterIP Service 和 PVC
- [ ] 后端使用 Deployment 和 ClusterIP Service，Service 名固定为 `backend`、端口固定为 `18080`，与 `nginx.conf` 保持一致
- [ ] SvelteKit SSR 使用 Deployment 和 ClusterIP Service，Service 名固定为 `frontend-app`、端口固定为 `3000`
- [ ] Nginx 网关使用独立 Deployment 和 ClusterIP Service，并通过 ConfigMap 挂载 `nginx.conf`
- [ ] 后端 liveness 使用 `/actuator/health/liveness`
- [ ] 后端 readiness 使用 `/actuator/health/readiness`
- [ ] SvelteKit SSR 和 Nginx 网关 probe 使用 `/`
- [ ] 后端、SvelteKit SSR、Nginx 网关和 MySQL 配置 CPU、内存 requests 和 limits
- [ ] 非敏感配置放入 ConfigMap
- [ ] MySQL 业务密码和 root 密码通过预先创建的 `ability-re-secrets` Secret 注入，不通过 Helm `--set` 传值
- [ ] `secret.example.yaml` 只保留占位符
- [ ] `/api` 由 Nginx 网关转发到 backend Service，其他请求转发到 frontend-app Service
- [ ] 校验 Helm Chart：

```bash
helm lint deploy/helm/ability-re -f deploy/helm/ability-re/values-local.yaml
helm template ability-re deploy/helm/ability-re \
  -f deploy/helm/ability-re/values-local.yaml \
  | kubectl apply --dry-run=client -f -
```

## 5. 本地数据库策略

本地 Minikube 只使用测试数据，不直接连接线上 MySQL。

- [ ] 为本地 MySQL 生成独立密码
- [ ] 使用 Kubernetes Secret 注入 MySQL 业务密码和 root 密码
- [ ] 使用 PVC 保存本地测试数据
- [ ] 验证 Minikube 重启后数据仍然存在
- [ ] 明确接受 `minikube delete` 会删除本地集群和本地测试数据
- [ ] 如需使用线上结构，只导入脱敏后的备份，不导入真实敏感数据

## 6. 部署到本地 Minikube

- [ ] 在不回显密码的情况下创建 Secret：

```bash
kubectl create namespace ability-re --dry-run=client -o yaml | kubectl apply -f -
read -s "LOCAL_DB_PASSWORD?Local MySQL password: "
echo
read -s "LOCAL_DB_ROOT_PASSWORD?Local MySQL root password: "
echo
kubectl -n ability-re create secret generic ability-re-secrets \
  --from-literal=mysql-password="$LOCAL_DB_PASSWORD" \
  --from-literal=mysql-root-password="$LOCAL_DB_ROOT_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -
unset LOCAL_DB_PASSWORD LOCAL_DB_ROOT_PASSWORD
```

- [ ] 安装本地 release：

```bash
TAG=$(git rev-parse --short HEAD)
helm upgrade --install ability-re deploy/helm/ability-re \
  --namespace ability-re \
  -f deploy/helm/ability-re/values-local.yaml \
  --set backend.image.tag="$TAG" \
  --set frontend.image.tag="$TAG" \
  --wait \
  --timeout 5m
```

- [ ] 查看资源与事件：

```bash
kubectl -n ability-re get pods,svc,pvc
kubectl -n ability-re get events --sort-by=.lastTimestamp
kubectl -n ability-re logs deployment/ability-re-backend
kubectl -n ability-re logs deployment/ability-re-frontend-app
kubectl -n ability-re logs deployment/ability-re-gateway
```

- [ ] 所有 Pod 达到 Ready，重启次数为 0
- [ ] PVC 状态为 Bound
- [ ] 首次访问先使用稳定的端口转发：

```bash
kubectl -n ability-re port-forward service/ability-re-gateway 18081:80
```

- [ ] 浏览器访问 `http://127.0.0.1:18081`
- [ ] 访问 `http://127.0.0.1:18081/api/health`
- [ ] 确认首页展示个人技术记录内容，且无联系表单、注册、支付或在线交易入口

## 7. 验证 Kubernetes 能力

- [ ] 删除一个 SvelteKit SSR Pod，确认 Deployment 在 5 分钟内自动恢复
- [ ] 删除一个 Nginx 网关 Pod，确认 Deployment 在 5 分钟内自动恢复
- [ ] 删除一个后端 Pod，确认 Deployment 在 5 分钟内自动恢复
- [ ] 修改镜像标签并执行 Helm upgrade，确认滚动更新成功
- [ ] 执行一次 Helm rollback：

```bash
helm history ability-re -n ability-re
helm rollback ability-re <REVISION> -n ability-re --wait
```

- [ ] 执行 `minikube stop` 后重新启动，确认 PVC 测试数据仍存在
- [ ] 观察 30 分钟，Pod 无异常重启，首页和健康接口持续可用

## 8. 本地 Ingress

端口转发验证完成后再启用 Ingress，避免同时排查应用和入口网络。

- [ ] 通过 Helm 安装 Traefik：

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm upgrade --install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --wait
kubectl -n traefik get pods,svc
```

- [ ] Helm Ingress class 和 host 分别使用 `traefik`、`ability-re.local`
- [ ] 根据 `minikube ip` 或本机网络方式配置 `/etc/hosts`
- [ ] macOS Docker driver 无法直接路由时，在独立终端运行 `minikube tunnel`
- [ ] 验证 `http://ability-re.local/` 和 `/api/health`

## 9. Woodpecker 边界

Woodpecker Agent 在阿里云服务器上，默认无法稳定访问位于家庭网络和笔记本中的 Minikube API。因此本地阶段不把 kubeconfig 上传到 Woodpecker，也不做远程自动部署。

- [x] Woodpecker 继续负责现有代码检查和线上 Compose 部署
- [ ] 本地 Minikube 使用 `helm upgrade` 手工部署
- [x] 已确认 Git 中没有 kubeconfig、真实 Secret 或本地数据库密码
- [ ] 可以新增本地脚本统一执行镜像构建、加载和 Helm upgrade
- [x] Woodpecker 不连接本地 Minikube，也不向现有 ECS 执行 Kubernetes CD

## 10. 生产 Kubernetes 规划（当前暂停）

现有 2 GB ECS 明确排除 Kubernetes，继续使用当前 Compose 部署。以下内容不是当前待办，仅在未来获得独立 ACK 或新集群资源后重新立项：

- 单独评估 ACK 成本，或准备不与当前生产 ECS 共用资源的新集群节点。
- 创建 ACR，并推送 commit SHA 镜像。
- 使用 RDS MySQL，完成备份、恢复和数据核对。
- 为 Woodpecker 配置最小权限 RBAC 和 Kubernetes CD。
- 在测试域名完成 HTTPS、健康检查、回滚和稳定性验证后，再单独制定生产切流计划。

## 11. 本地阶段验收标准

- [x] Docker Desktop、kubectl、Minikube、Helm 均可正常运行
- [x] Minikube 节点为 Ready，默认 StorageClass 可用
- [ ] Nginx 网关、SvelteKit SSR、后端、MySQL Pod 均 Ready 且 30 分钟内无异常重启
- [ ] MySQL PVC 为 Bound，Minikube stop/start 后测试数据保留
- [ ] 首页、`/api/health` 均通过，且页面无联系表单、注册、支付或在线交易入口
- [ ] 删除 Nginx 网关、SvelteKit SSR 或后端 Pod 后均能在 5 分钟内恢复
- [ ] Helm upgrade 和 rollback 均成功
- [ ] Helm lint、template 和 dry-run 均成功
- [x] 仓库中不存在真实密码、私钥或 kubeconfig
- [ ] 线上 `http://8.136.60.154:18081` 在整个本地实验期间保持可用

完整设计说明见 `docs/plans/kubernetes-migration.md`。
