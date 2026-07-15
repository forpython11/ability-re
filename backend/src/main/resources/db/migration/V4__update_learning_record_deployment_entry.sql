UPDATE site_learning_records
SET title = '从零跑通部署入口：Minikube、Nginx 反向代理、域名解析与备案排查',
    summary = '这是一篇真实学习记录：目标不是背概念，而是把本机 Kubernetes 工具链、线上 Docker Compose、域名解析、Nginx 反向代理和个人备案限制串起来，记录每一步能跑通什么、卡在哪里以及下一步该做什么。',
    environment = 'macOS Intel / Docker Desktop / Minikube v1.38.1 / Kubernetes v1.30.5 / Alibaba Cloud Linux 3 / Nginx 1.24.0'
WHERE slug = 'kubernetes-minikube';

UPDATE site_learning_record_blocks b
SET b.body = '这次实践先完成了一条最小但完整的 Kubernetes 本地部署链路：准备本机容器运行环境，启动一个单节点 Kubernetes 集群，把一个 Nginx 容器以 Deployment 的形式运行起来，并通过 Service 暴露成本机可以访问的地址。

随后把注意力切回线上入口：购买并实名认证 `cinney.top`，将 `study.cinney.top` 解析到杭州 ECS 公网 IP `8.136.60.154`，在服务器安装宿主机 Nginx，再把标准 80 端口反向代理到已有 Docker Compose 前端端口 `127.0.0.1:18081`。

kubectl 是操作 Kubernetes 的命令行工具；Minikube 是本机单节点 Kubernetes 集群；Helm 是后续把一组 Kubernetes YAML 打包成可重复安装应用的包管理工具。'
WHERE b.record_id = (SELECT id FROM site_learning_records WHERE slug = 'kubernetes-minikube')
  AND b.heading = '我到底做了什么';

UPDATE site_learning_record_blocks b
SET b.body = '本地 Minikube 集群已经正常运行，Nginx 测试 Pod 已达到 1/1 Running。这说明 Kubernetes 集群、Pod 调度、镜像加载、Service 暴露和本机访问都已经打通。

线上入口也完成了 HTTP 层面的最小闭环：`study.cinney.top` 已解析到 ECS，宿主机 Nginx 已启动，`http://study.cinney.top/` 能通过 80 端口转发到 `127.0.0.1:18081` 并返回 SvelteKit 页面。',
    b.code_sample = 'minikube status
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured

kubectl get pods
nginx-86bffb8c6b-z4sc7   1/1   Running   0   26s

minikube service nginx --url
http://127.0.0.1:52969

curl -I http://127.0.0.1:18081/
HTTP/1.1 200 OK

curl -I http://study.cinney.top/
HTTP/1.1 200 OK'
WHERE b.record_id = (SELECT id FROM site_learning_records WHERE slug = 'kubernetes-minikube')
  AND b.heading = '最终跑通的结果';

DELETE FROM site_learning_record_blocks
WHERE record_id = (SELECT id FROM site_learning_records WHERE slug = 'kubernetes-minikube')
  AND heading IN ('配置线上域名和宿主机 Nginx', '备案和 HTTPS 的真实阻塞');

UPDATE site_learning_record_blocks b
SET b.sort_order = b.sort_order + 2
WHERE b.record_id = (SELECT id FROM site_learning_records WHERE slug = 'kubernetes-minikube')
  AND b.sort_order >= 6;

INSERT INTO site_learning_record_blocks (record_id, block_type, heading, body, code_sample, sort_order)
SELECT id, 'step', '配置线上域名和宿主机 Nginx',
       'DNS 解析只能把域名指向 IP，不能直接指向端口。为了让 `http://study.cinney.top/` 不带端口访问，需要让域名解析到 ECS 公网 IP，再由宿主机 Nginx 监听 80 端口并反向代理到 Compose 前端容器暴露出来的 `127.0.0.1:18081`。',
       'server {
    listen 80;
    server_name study.cinney.top;

    location / {
        proxy_pass http://127.0.0.1:18081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

nginx -t
systemctl reload nginx',
       6
FROM site_learning_records
WHERE slug = 'kubernetes-minikube';

INSERT INTO site_learning_record_blocks (record_id, block_type, heading, body, code_sample, sort_order)
SELECT id, 'problem', '备案和 HTTPS 的真实阻塞',
       '在杭州 ECS 上，域名实名认证通过不等于 ICP 备案通过。HTTP 可以先通过 Nginx 转发跑通，但申请 Let''s Encrypt 证书时，HTTP-01 校验需要公网访问 `/.well-known/acme-challenge/...`。未备案状态下，阿里云会把域名 80 端口访问拦截为 `Non-compliance ICP Filing` 的 403 页面，导致 Certbot 无法完成校验。

备案系统还要求域名获得备案号前保持关闭状态，因此提交备案前需要暂停 `cinney.top`、`www.cinney.top` 等被要求关闭的解析。备案通过后再恢复解析，并重新执行 Certbot 申请 HTTPS 证书。',
       'certbot --nginx -d study.cinney.top

Certbot failed to authenticate some domains
Detail: Invalid response from http://study.cinney.top/.well-known/acme-challenge/...: 403

curl -i http://study.cinney.top/.well-known/acme-challenge/test
HTTP/1.1 403 Forbidden
Server: Beaver
<title>Non-compliance ICP Filing</title>',
       7
FROM site_learning_records
WHERE slug = 'kubernetes-minikube';

UPDATE site_learning_record_blocks b
SET b.body = '能解释 kubectl、Minikube、Helm 在 Kubernetes 工作流里的职责边界。
能在 macOS 本机启动 Minikube Kubernetes 集群，并用 kubectl 查看 Node、Pod、Service。
能根据 Pod 状态区分是调度问题、容器创建问题，还是镜像拉取问题。
能使用 Deployment 和 Service 部署一个最小可访问应用。
能解释 DNS 只能解析到 IP、不能解析到端口，并用 Nginx 把标准 80 端口反向代理到内部应用端口。
能区分域名实名认证、DNS 解析、ICP备案和 HTTPS 证书申请分别解决的问题。
能把网络和镜像源问题记录成可复用的排查步骤，而不是停留在“命令跑不通”。'
WHERE b.record_id = (SELECT id FROM site_learning_records WHERE slug = 'kubernetes-minikube')
  AND b.heading = '我现在具备的能力';

UPDATE site_learning_record_blocks b
SET b.body = '接下来先完成个人 ICP 备案前置要求：按提示暂停根域名和 www 解析，提交备案审核。备案通过后恢复 DNS，重新申请 HTTPS 证书，并把公网规范地址从临时 HTTP 逐步切到 HTTPS。

部署侧会继续把本站本身 Kubernetes 化：为前端和后端编写 Dockerfile，构建本地镜像，加载到 Minikube，再用 Helm Chart 管理前端、后端、MySQL、Secret、ConfigMap、Service 和 PVC。'
WHERE b.record_id = (SELECT id FROM site_learning_records WHERE slug = 'kubernetes-minikube')
  AND b.heading = '下一步';
