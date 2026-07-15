CREATE TABLE site_learning_records (
    id BIGINT NOT NULL AUTO_INCREMENT,
    slug VARCHAR(120) NOT NULL,
    title VARCHAR(220) NOT NULL,
    summary TEXT NOT NULL,
    category VARCHAR(120) NOT NULL,
    environment VARCHAR(220) NOT NULL,
    published_at DATE NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_site_learning_records_slug (slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE site_learning_record_blocks (
    id BIGINT NOT NULL AUTO_INCREMENT,
    record_id BIGINT NOT NULL,
    block_type VARCHAR(40) NOT NULL,
    heading VARCHAR(180) NOT NULL,
    body TEXT NOT NULL,
    code_sample TEXT,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_learning_record_blocks_record_order (record_id, sort_order),
    CONSTRAINT fk_learning_record_blocks_record
        FOREIGN KEY (record_id) REFERENCES site_learning_records (id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO site_learning_records (slug, title, summary, category, environment, published_at) VALUES
('kubernetes-minikube',
 '从零跑通本地 Kubernetes：kubectl、Minikube、Helm 与 Nginx 部署',
 '这是一篇真实学习记录：目标不是背概念，而是在本机把 Kubernetes 工具链装好，启动一个可用集群，部署一个 Nginx 应用，并在遇到网络、镜像和 Pod 状态问题时一步步定位原因。',
 'Kubernetes learning record',
 'macOS Intel / Docker Desktop / Minikube v1.38.1 / Kubernetes v1.30.5',
 '2026-07-14');

INSERT INTO site_learning_record_blocks (record_id, block_type, heading, body, code_sample, sort_order)
SELECT id, 'section', '我到底做了什么',
       '这次实践完成的是一条最小但完整的 Kubernetes 本地部署链路：先准备本机容器运行环境，再启动一个单节点 Kubernetes 集群，然后把一个 Nginx 容器以 Deployment 的形式运行起来，并通过 Service 暴露成本机可以访问的地址。

kubectl 是操作 Kubernetes 的命令行工具；Minikube 是本机单节点 Kubernetes 集群；Helm 是后续把一组 Kubernetes YAML 打包成可重复安装应用的包管理工具。',
       NULL,
       1
FROM site_learning_records WHERE slug = 'kubernetes-minikube';

INSERT INTO site_learning_record_blocks (record_id, block_type, heading, body, code_sample, sort_order)
SELECT id, 'result', '最终跑通的结果',
       '本地 Minikube 集群已经正常运行，Nginx 测试 Pod 已达到 1/1 Running。这说明 Kubernetes 集群、Pod 调度、镜像加载、Service 暴露和本机访问都已经打通。',
       'minikube status
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured

kubectl get pods
nginx-86bffb8c6b-z4sc7   1/1   Running   0   26s

minikube service nginx --url
http://127.0.0.1:52969',
       2
FROM site_learning_records WHERE slug = 'kubernetes-minikube';

INSERT INTO site_learning_record_blocks (record_id, block_type, heading, body, code_sample, sort_order)
SELECT id, 'step', '安装命令行工具',
       '一开始尝试用 Homebrew 安装 kubectl，但 Homebrew 需要从 GitHub Container Registry 下载 bottle，国内网络很慢。后来改成直接下载 macOS Intel 的二进制文件，分别安装 kubectl、Minikube 和 Helm。',
       NULL,
       3
FROM site_learning_records WHERE slug = 'kubernetes-minikube';

INSERT INTO site_learning_record_blocks (record_id, block_type, heading, body, code_sample, sort_order)
SELECT id, 'step', '启动 Minikube 集群',
       'Minikube 使用 Docker 驱动时，本质上是在 Docker Desktop 里创建一个 Kubernetes 节点容器。最终稳定启动命令是固定 Kubernetes 版本，不额外指定国内 Kubernetes release 镜像源。',
       'minikube start \
  --driver=docker \
  --kubernetes-version=v1.30.5',
       4
FROM site_learning_records WHERE slug = 'kubernetes-minikube';

INSERT INTO site_learning_record_blocks (record_id, block_type, heading, body, code_sample, sort_order)
SELECT id, 'step', '创建 Nginx Deployment 和 Service',
       'Deployment 负责声明“我要运行一个 Nginx 应用”；Service 负责给这个应用一个稳定入口。',
       'kubectl create deployment nginx --image=docker.m.daocloud.io/library/nginx:alpine
kubectl expose deployment nginx --type=NodePort --port=80',
       5
FROM site_learning_records WHERE slug = 'kubernetes-minikube';

INSERT INTO site_learning_record_blocks (record_id, block_type, heading, body, code_sample, sort_order)
SELECT id, 'problem', '这次真正学到的排查经验',
       'Homebrew 下载慢：brew install kubectl 长时间卡在下载 bottle，根因是访问 ghcr.io 慢，处理方式是绕过 Homebrew，直接下载官方二进制文件。

错误页面被当成可执行文件：国内镜像地址下载到 HTML/XML 错误页，经验是下载命令加 curl -fL，让 HTTP 错误直接失败。

阿里云 OSS sha256 404：使用 --image-mirror-country=cn 或特定 --image-repository 时，Minikube 会访问缺失 .sha256 文件的 Kubernetes release 路径。

ImagePullBackOff 不是应用坏了：Nginx Pod 出现 ErrImagePull / ImagePullBackOff，根因是 Docker Hub 超时，解决方式是使用国内代理镜像并通过 minikube image load 导入集群。',
       NULL,
       6
FROM site_learning_records WHERE slug = 'kubernetes-minikube';

INSERT INTO site_learning_record_blocks (record_id, block_type, heading, body, code_sample, sort_order)
SELECT id, 'capability', '我现在具备的能力',
       '能解释 kubectl、Minikube、Helm 在 Kubernetes 工作流里的职责边界。
能在 macOS 本机启动 Minikube Kubernetes 集群，并用 kubectl 查看 Node、Pod、Service。
能根据 Pod 状态区分是调度问题、容器创建问题，还是镜像拉取问题。
能使用 Deployment 和 Service 部署一个最小可访问应用。
能把网络和镜像源问题记录成可复用的排查步骤，而不是停留在“命令跑不通”。',
       NULL,
       7
FROM site_learning_records WHERE slug = 'kubernetes-minikube';

INSERT INTO site_learning_record_blocks (record_id, block_type, heading, body, code_sample, sort_order)
SELECT id, 'next', '下一步',
       '接下来会把本站本身继续 Kubernetes 化：为前端和后端编写 Dockerfile，构建本地镜像，加载到 Minikube，再用 Helm Chart 管理前端、后端、MySQL、Secret、ConfigMap、Service 和 PVC。',
       NULL,
       8
FROM site_learning_records WHERE slug = 'kubernetes-minikube';
