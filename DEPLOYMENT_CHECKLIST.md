# Ability Re 部署与本地 Kubernetes 清单

> 当前线上环境：Docker Compose 已部署到 `http://8.136.60.154:18081`，并通过宿主机 Nginx 将 `http://study.cinney.top/` 反向代理到 `127.0.0.1:18081`。
> 当前目标：完成个人备案前置处理，备案通过前暂停 `cinney.top`、`www.cinney.top` 等备案要求关闭的域名解析；本地 Kubernetes 实验不影响线上环境。
> 后续目标：备案通过后恢复域名解析、签发 HTTPS 证书，再继续本地 Helm Chart 验证并迁移到阿里云 ACK 或 kubeadm 集群。

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
- [ ] 再推送一次提交，确认线上 Compose 可以完全自动更新

本地 Kubernetes 建设期间不关闭、不修改线上 Docker Compose。公网入口当前包括前端调试端口 `18081` 和 Nginx `80`；后端 `18080` 和 MySQL `3306` 不开放。由于杭州 ECS 未备案域名访问会被阿里云返回 `Non-compliance ICP Filing` 的 403 页面，Let's Encrypt HTTP-01 校验暂时不能通过，HTTPS 配置需要等备案通过后再继续。

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

当前验证结果：`nginx` Pod 已达到 `1/1 Running`，`minikube service nginx --url` 已输出本地访问地址。

注意：本机启动 Minikube 时不要加 `--image-mirror-country=cn` 或 `--image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers`，否则会触发阿里云 OSS Kubernetes release `.sha256` 文件 404。Docker Hub 拉业务镜像可能超时，测试镜像优先使用国内代理并通过 `minikube image load` 导入。

## 3. 应用镜像化

- [ ] 新增 `backend/Dockerfile`
- [ ] 后端使用 Java 21 多阶段构建，运行阶段只包含 JRE
- [ ] 后端容器使用非 root 用户
- [ ] 新增 `frontend/Dockerfile`
- [ ] 前端使用 Node 22 + pnpm 构建，运行阶段使用 nginx
- [ ] 新增 `.dockerignore`，排除 `.git`、`node_modules`、`target`、`build`、`.env` 和本地缓存
- [ ] 构建本地镜像：

```bash
TAG=$(git rev-parse --short HEAD)
docker build -t "ability-re-backend:$TAG" backend
docker build -t "ability-re-frontend:$TAG" frontend
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
            ├── frontend-deployment.yaml
            ├── frontend-service.yaml
            ├── ingress.yaml
            ├── configmap.yaml
            └── secret.example.yaml
```

- [ ] 创建 Namespace：`ability-re`
- [ ] MySQL 使用 StatefulSet、ClusterIP Service 和 PVC
- [ ] 后端使用 Deployment 和 ClusterIP Service，Service 名固定为 `backend`、端口固定为 `18080`，与 `nginx.conf` 保持一致
- [ ] 前端使用 Deployment 和 ClusterIP Service
- [ ] 后端 liveness 使用 `/actuator/health/liveness`
- [ ] 后端 readiness 使用 `/actuator/health/readiness`
- [ ] 前端 probe 使用 `/`
- [ ] 前后端配置 CPU、内存 requests 和 limits
- [ ] 非敏感配置放入 ConfigMap
- [ ] 数据库密码通过预先创建的 `ability-re-secrets` Secret 注入，不通过 Helm `--set` 传值
- [ ] `secret.example.yaml` 只保留占位符
- [ ] `/api` 通过前端 nginx 或 Ingress 转发到 backend Service
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
- [ ] 使用 Kubernetes Secret 注入数据库密码
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
kubectl -n ability-re create secret generic ability-re-secrets \
  --from-literal=mysql-password="$LOCAL_DB_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -
unset LOCAL_DB_PASSWORD
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
```

- [ ] 所有 Pod 达到 Ready，重启次数为 0
- [ ] PVC 状态为 Bound
- [ ] 首次访问先使用稳定的端口转发：

```bash
kubectl -n ability-re port-forward service/ability-re-frontend 18081:80
```

- [ ] 浏览器访问 `http://127.0.0.1:18081`
- [ ] 访问 `http://127.0.0.1:18081/api/health`
- [ ] 确认首页展示个人技术记录内容，且无联系表单、注册、支付或在线交易入口

## 7. 验证 Kubernetes 能力

- [ ] 删除一个前端 Pod，确认 Deployment 在 5 分钟内自动恢复
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

- [ ] Woodpecker 继续负责现有代码检查和线上 Compose 部署
- [ ] 本地 Minikube 使用 `helm upgrade` 手工部署
- [ ] Git 中不提交 kubeconfig、真实 Secret 或本地数据库密码
- [ ] 可以新增本地脚本统一执行镜像构建、加载和 Helm upgrade
- [ ] 云端 Kubernetes 准备好后，再启用 Woodpecker Kubernetes CD

## 10. 后续迁移到云端 Kubernetes

本地验收通过后再执行以下阶段：

- [ ] 选择阿里云 ACK，或独立 ECS 上的 `kubeadm + containerd`
- [ ] 创建阿里云 ACR，并推送 commit SHA 镜像
- [ ] 使用 RDS MySQL，完成备份、恢复和数据核对
- [ ] 使用 `values-prod.yaml` 替换本地镜像、存储和域名配置
- [ ] 为 Woodpecker 创建 Namespace 级别的 ServiceAccount 和 RBAC
- [ ] 使用 `helm upgrade --install --atomic --wait` 自动部署
- [ ] 配置域名、HTTPS、健康检查和回滚
- [ ] 云端稳定运行 24 小时后，再关闭旧 Compose 公网入口

## 11. 本地阶段验收标准

- [ ] Docker Desktop、kubectl、Minikube、Helm 均可正常运行
- [ ] Minikube 节点为 Ready
- [ ] 前端、后端、MySQL Pod 均 Ready 且 30 分钟内无异常重启
- [ ] MySQL PVC 为 Bound，Minikube stop/start 后测试数据保留
- [ ] 首页、`/api/health` 均通过，且页面无联系表单、注册、支付或在线交易入口
- [ ] 删除前后端 Pod 后均能在 5 分钟内恢复
- [ ] Helm upgrade 和 rollback 均成功
- [ ] Helm lint、template 和 dry-run 均成功
- [ ] 仓库中不存在真实密码、私钥或 kubeconfig
- [ ] 线上 `http://8.136.60.154:18081` 在整个本地实验期间保持可用

完整设计说明见 `docs/plans/kubernetes-migration.md`。
