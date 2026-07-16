-- Dockerfile 和本地镜像构建已经完成，把学习记录的下一步推进到 Minikube 与 Helm 阶段。
UPDATE site_learning_record_blocks b
SET b.body = '个人 ICP 备案仍按管局流程独立推进：备案通过后恢复 DNS，重新申请 HTTPS 证书，并把公网规范地址从临时 HTTP 切换到 HTTPS。

部署侧已经完成前后端 Dockerfile、非 root 运行和本地镜像构建验证。下一步使用当前 Git SHA 重新构建镜像并加载到 Minikube，再创建 Helm Chart 管理 MySQL、Spring Boot 后端、SvelteKit SSR、Nginx 网关、Secret、ConfigMap、Service 和 PVC。'
WHERE b.record_id = (SELECT id FROM site_learning_records WHERE slug = 'kubernetes-minikube')
  AND b.heading = '下一步';
