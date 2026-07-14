# macOS Intel 本地 Kubernetes 环境搭建记录

本文记录在 macOS Intel 机器上安装并跑通 `kubectl`、Minikube、Helm、Docker Desktop 和一个 Nginx 测试应用的过程。

## 完整操作步骤

如果从零开始，按下面顺序执行即可。

### 第 1 步：确认 Docker Desktop 正在运行

先打开 Docker Desktop，然后执行：

```bash
docker version
```

正常情况下应同时看到 `Client` 和 `Server` 信息。如果只有 `Client`，或提示无法连接 Docker daemon，说明 Docker Desktop 还没启动成功。

### 第 2 步：清理之前可能下载错的文件

如果之前下载过错误的 `kubectl`、`minikube` 或 `helm` 文件，先清理：

```bash
sudo rm -f /usr/local/bin/kubectl /usr/local/bin/minikube /usr/local/bin/helm
rm -f ~/kubectl ~/minikube ~/helm.tar.gz
rm -rf ~/darwin-amd64
```

### 第 3 步：安装 kubectl

```bash
cd ~

KUBECTL_VERSION="v1.30.5"
curl -fL --retry 3 -o kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/darwin/amd64/kubectl"
file kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl

kubectl version --client
```

正常应看到类似：

```text
Client Version: v1.30.5
```

### 第 4 步：安装 Minikube

```bash
cd ~

curl -fL --retry 3 -o minikube "https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64"
file minikube
chmod +x minikube
sudo mv minikube /usr/local/bin/minikube

minikube version
```

正常应看到类似：

```text
minikube version: v1.38.1
```

### 第 5 步：安装 Helm

```bash
cd ~

HELM_VERSION="v3.16.2"
curl -fL --retry 3 -o helm.tar.gz "https://get.helm.sh/helm-${HELM_VERSION}-darwin-amd64.tar.gz"
file helm.tar.gz
tar -zxvf helm.tar.gz
sudo mv darwin-amd64/helm /usr/local/bin/helm
rm -rf darwin-amd64 helm.tar.gz

helm version
```

正常应看到类似：

```text
Version:"v3.16.2"
```

### 第 6 步：启动 Minikube 集群

不要加 `--image-mirror-country=cn`，也不要加 `--image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers`，否则可能触发阿里云 OSS 的 `.sha256` 文件 404。

```bash
minikube delete

minikube start \
  --driver=docker \
  --kubernetes-version=v1.30.5
```

成功后应看到类似：

```text
完成！kubectl 现在已配置，默认使用"minikube"集群和"default"命名空间
```

### 第 7 步：验证集群状态

```bash
minikube status
kubectl get nodes
kubectl get pods -A
```

正常情况下：

- `minikube status` 中 `host`、`kubelet`、`apiserver`、`kubeconfig` 都应正常。
- `kubectl get nodes` 应看到 `minikube` 节点为 `Ready`。

### 第 8 步：拉取国内代理 Nginx 镜像

本机 Docker Hub 可能超时，不建议直接用 `nginx:latest`。优先使用国内代理镜像：

```bash
docker pull docker.m.daocloud.io/library/nginx:alpine
```

如果该源失败，可换用：

```bash
docker pull docker.1ms.run/library/nginx:alpine
```

或：

```bash
docker pull docker.1panel.live/library/nginx:alpine
```

### 第 9 步：把镜像导入 Minikube

如果第 8 步使用的是 DaoCloud 镜像，执行：

```bash
minikube image load docker.m.daocloud.io/library/nginx:alpine
```

如果第 8 步换了其他镜像源，这里也要替换成相同镜像名。

### 第 10 步：创建 Nginx Deployment 和 Service

```bash
kubectl delete service nginx --ignore-not-found
kubectl delete deployment nginx --ignore-not-found

kubectl create deployment nginx --image=docker.m.daocloud.io/library/nginx:alpine
kubectl expose deployment nginx --type=NodePort --port=80

kubectl get pods
kubectl get svc
```

如果镜像源使用的不是 `docker.m.daocloud.io/library/nginx:alpine`，这里的 `--image=` 也要换成相同镜像。

### 第 11 步：等待 Pod 运行成功

```bash
kubectl get pods
```

正常应看到：

```text
NAME                     READY   STATUS    RESTARTS   AGE
nginx-xxxxxxxxxx-xxxxx   1/1     Running   0          ...
```

如果看到 `ContainerCreating`，等几十秒再查一次。

如果看到 `ImagePullBackOff` 或 `ErrImagePull`，说明镜像拉取失败，需要换第 8 步的镜像源。

### 第 12 步：访问 Nginx

```bash
minikube service nginx --url
```

示例输出：

```text
http://127.0.0.1:52969
```

复制这个地址到浏览器打开即可。

macOS + Docker 驱动下，`minikube service nginx --url` 会保持一个临时转发进程。访问期间不要关闭该终端，也不要按 `Control + C`。

### 第 13 步：停止访问或清理测试应用

如果只想停止访问，在运行 `minikube service nginx --url` 的终端按：

```text
Control + C
```

如果要删除 Nginx 测试应用：

```bash
kubectl delete service nginx
kubectl delete deployment nginx
```

### 第 14 步：停止或删除 Minikube

停止集群：

```bash
minikube stop
```

下次启动：

```bash
minikube start --driver=docker --kubernetes-version=v1.30.5
```

彻底删除集群：

```bash
minikube delete
```

## 环境信息

```text
系统：macOS Darwin 26.5.2
芯片：Intel / amd64 / x86_64
Docker：Docker Desktop 29.2.1
kubectl：v1.30.5
Minikube：v1.38.1
Helm：v3.16.2
Kubernetes：v1.30.5
```

## 1. 安装 kubectl、Minikube、Helm

Homebrew 在国内访问 `ghcr.io` 可能很慢，因此本次改为直接下载二进制文件安装。

### kubectl

```bash
cd ~

KUBECTL_VERSION="v1.30.5"
curl -fL --retry 3 -o kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/darwin/amd64/kubectl"
file kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl

kubectl version --client
```

正常输出中应包含：

```text
Client Version: v1.30.5
```

### Minikube

```bash
cd ~

curl -fL --retry 3 -o minikube "https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64"
file minikube
chmod +x minikube
sudo mv minikube /usr/local/bin/minikube

minikube version
```

正常输出中应包含：

```text
minikube version: v1.38.1
```

### Helm

```bash
cd ~

HELM_VERSION="v3.16.2"
curl -fL --retry 3 -o helm.tar.gz "https://get.helm.sh/helm-${HELM_VERSION}-darwin-amd64.tar.gz"
file helm.tar.gz
tar -zxvf helm.tar.gz
sudo mv darwin-amd64/helm /usr/local/bin/helm
rm -rf darwin-amd64 helm.tar.gz

helm version
```

正常输出中应包含：

```text
Version:"v3.16.2"
```

## 2. 启动 Minikube

本机已经安装 Docker Desktop，因此使用 Docker 驱动启动 Minikube。

> 注意：本次不要添加 `--image-mirror-country=cn` 或 `--image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers`。这些参数会导致 Minikube 访问 `kubernetes.oss-cn-hangzhou.aliyuncs.com/kubernetes-release/...` 下载 Kubernetes 二进制文件，而该源部分版本的 `.sha256` 文件返回 404。

```bash
minikube delete

minikube start \
  --driver=docker \
  --kubernetes-version=v1.30.5
```

启动成功时会看到类似：

```text
完成！kubectl 现在已配置，默认使用"minikube"集群和"default"命名空间
```

验证集群：

```bash
minikube status
kubectl get nodes
kubectl get pods -A
```

`kubectl get nodes` 正常应看到：

```text
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   ...   v1.30.5
```

## 3. 部署 Nginx 测试应用

由于本地 Docker 访问 Docker Hub 可能超时，优先使用国内代理镜像。

### 拉取镜像

```bash
docker pull docker.m.daocloud.io/library/nginx:alpine
```

如果该源不可用，可尝试：

```bash
docker pull docker.1ms.run/library/nginx:alpine
```

或：

```bash
docker pull docker.1panel.live/library/nginx:alpine
```

### 导入 Minikube

以 DaoCloud 镜像为例：

```bash
minikube image load docker.m.daocloud.io/library/nginx:alpine
```

### 创建 Deployment 和 Service

```bash
kubectl delete service nginx --ignore-not-found
kubectl delete deployment nginx --ignore-not-found

kubectl create deployment nginx --image=docker.m.daocloud.io/library/nginx:alpine
kubectl expose deployment nginx --type=NodePort --port=80
kubectl get pods
kubectl get svc
```

Pod 正常运行时应看到：

```text
NAME                     READY   STATUS    RESTARTS   AGE
nginx-xxxxxxxxxx-xxxxx   1/1     Running   0          ...
```

## 4. 访问 Nginx

```bash
minikube service nginx --url
```

示例输出：

```text
http://127.0.0.1:52969
```

在浏览器打开该地址即可访问 Nginx 页面。

macOS + Docker 驱动下可能会提示：

```text
因为你正在使用 darwin 上的 Docker 驱动程序，所以需要打开终端才能运行它。
```

这不是错误。意思是 `minikube service` 会在当前终端里保持一个临时端口转发进程。访问期间不要关闭该终端，也不要按 `Control + C`。

如果要停止访问，回到运行 `minikube service nginx --url` 的终端按：

```text
Control + C
```

## 5. 清理测试应用

```bash
kubectl delete service nginx
kubectl delete deployment nginx
```

## 6. 停止或删除 Minikube

停止集群：

```bash
minikube stop
```

下次重新启动：

```bash
minikube start --driver=docker --kubernetes-version=v1.30.5
```

彻底删除集群：

```bash
minikube delete
```

## 7. 常见问题

### Homebrew 安装 kubectl 卡住

现象：

```text
brew install kubectl
Bottle kubernetes-cli ... Downloading
```

原因：Homebrew 从 `ghcr.io` 下载 bottle，国内网络可能很慢。

处理：直接使用本文的二进制安装方式。

### 下载后执行 kubectl/minikube 报 HTML/XML 语法错误

现象：

```text
/usr/local/bin/kubectl: line 1: syntax error near unexpected token `newline'
/usr/local/bin/kubectl: line 1: `<!DOCTYPE html>'

/usr/local/bin/minikube: line 1: `<?xml version="1.0" encoding="UTF-8"?>'
```

原因：下载地址返回了错误页面，但文件仍被保存并移动到了 `/usr/local/bin`。

处理：删除错误文件后使用 `curl -fL` 重新下载。

```bash
sudo rm -f /usr/local/bin/kubectl /usr/local/bin/minikube /usr/local/bin/helm
```

### Minikube 使用国内参数时报 sha256 404

现象：

```text
invalid checksum: Error downloading checksum file: bad response code: 404
https://kubernetes.oss-cn-hangzhou.aliyuncs.com/kubernetes-release/release/v1.30.5/...
```

原因：阿里云 OSS 的 Kubernetes release 镜像路径不完整，部分 `.sha256` 文件不存在。

处理：启动 Minikube 时不要加 `--image-mirror-country=cn` 和 `--image-repository=...`，改用：

```bash
minikube start --driver=docker --kubernetes-version=v1.30.5
```

### Nginx Pod 出现 ImagePullBackOff

现象：

```text
STATUS
ImagePullBackOff
```

原因：Kubernetes 节点无法拉取 Docker Hub 上的 `nginx:latest` 等镜像。

处理：使用国内代理镜像，并先通过 Docker 拉取后导入 Minikube。

```bash
docker pull docker.m.daocloud.io/library/nginx:alpine
minikube image load docker.m.daocloud.io/library/nginx:alpine
```

然后重新创建 Deployment。

## 8. 当前已验证结果

本次已验证：

```text
kubectl version --client     ✅
minikube version             ✅
helm version                 ✅
minikube start               ✅
kubectl get pods             ✅
nginx Pod 1/1 Running        ✅
minikube service nginx --url ✅
```
