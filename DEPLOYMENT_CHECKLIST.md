# Woodpecker 部署后续清单

## 1. 更新 Woodpecker Secrets

- [ ] 进入 Woodpecker：`ability-re -> Settings -> Secrets`
- [ ] 删除旧的 `deploy_ssh_key`
- [ ] 在 Mac 上执行 `cat ~/.ssh/woodpecker_deploy_nopass`
- [ ] 复制完整私钥内容到新的 `deploy_ssh_key`
- [ ] `deploy_ssh_key` 的 Events 只勾选 `Push`
- [ ] 确认插件限制留空
- [ ] 确认以下 secrets 都存在：

| Name | Value |
| --- | --- |
| `deploy_host` | `8.136.60.154` |
| `deploy_port` | `22` |
| `deploy_user` | `root` |
| `deploy_path` | `/opt/ability-re` |
| `deploy_ssh_key` | Mac 上 `~/.ssh/woodpecker_deploy_nopass` 的完整私钥内容 |
| `deploy_restart_cmd` | `echo "deploy done"` |

## 2. 重新运行 Woodpecker 流水线

- [ ] 回到 Woodpecker 的 `ability-re` 仓库页面
- [ ] 重新运行最新一次 pipeline，或推送一个空提交触发：

```bash
git commit --allow-empty -m "ci: trigger deployment"
git push origin main
```

- [ ] 确认 `backend` 步骤成功
- [ ] 确认 `frontend` 步骤成功
- [ ] 确认 `package` 步骤成功
- [ ] 确认 `deploy` 步骤成功

## 3. 验证服务器文件

- [ ] 登录服务器：

```bash
ssh root@8.136.60.154
```

- [ ] 查看部署目录：

```bash
cd /opt/ability-re
ls -la
```

- [ ] 确认能看到 `dist/`、`docker-compose.yml`、`README.md`

## 4. 放行新端口

- [ ] 阿里云 ECS 安全组放行 TCP `18080`
- [ ] 如果服务器启用了 firewalld，执行：

```bash
firewall-cmd --add-port=18080/tcp --permanent
firewall-cmd --reload
```

- [ ] 确认 `18080` 当前未被占用：

```bash
ss -lntp | grep 18080
```

## 5. 启动项目

- [ ] 先确认 MySQL 是否已启动：

```bash
cd /opt/ability-re
docker compose up -d mysql
docker compose ps
```

- [ ] 启动后端服务，确认它监听 `18080`
- [ ] 测试后端健康接口：

```bash
curl http://127.0.0.1:18080/api/health
```

- [ ] 浏览器访问：

```text
http://8.136.60.154:18080/api/health
```

## 6. 最后改成自动重启

- [ ] 手动部署确认没问题后，再更新 Woodpecker secret：

| Name | Value |
| --- | --- |
| `deploy_restart_cmd` | `cd /opt/ability-re && docker compose up -d --build` |

- [ ] 再推送一次代码，确认后续可以自动部署。
