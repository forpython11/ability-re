#!/bin/sh

# 任一命令失败或使用未定义变量时立即停止，避免半完成部署继续执行。
set -eu

deploy_path=${1:?deployment path is required}
archive=${2:?release archive is required}
staging=$(mktemp -d)

# shellcheck disable=SC2329  # Invoked by the EXIT trap.
cleanup() {
  rm -rf "$staging"
  rm -f "$archive" /tmp/deploy-frontend.sh
}
# EXIT trap 确保服务器不积累包含发布产物的临时文件。
trap cleanup EXIT

# adapter-node 产物必须同时包含入口、客户端资源和服务端代码。
test -f "$deploy_path/.env"
test -f "$archive"
tar -tzf "$archive" >/dev/null
tar -xzf "$archive" -C "$staging"
test -d "$staging/dist/frontend"
test -f "$staging/dist/frontend/index.js"
test -d "$staging/dist/frontend/client"
test -d "$staging/dist/frontend/server"
test -f "$staging/docker-compose.yml"
test -f "$staging/nginx.conf"

mkdir -p "$deploy_path/dist"
cd "$deploy_path"

# 与后端部署共享锁，避免同时替换 Compose 配置和 dist 目录。
exec 9>"$deploy_path/.deploy.lock"
command -v flock >/dev/null
flock -w 300 9

install -m 644 "$staging/docker-compose.yml" docker-compose.yml
install -m 644 "$staging/nginx.conf" nginx.conf
# 在 next 目录组装完整版本，最后一次改名切换，减少不可用窗口。
rm -rf dist/frontend.next
mkdir -p dist/frontend.next
cp -R "$staging/dist/frontend/." dist/frontend.next/
rm -rf dist/frontend
mv dist/frontend.next dist/frontend

docker compose up -d --no-deps --force-recreate frontend-app frontend

# 最多等待 60 秒，公网入口容器能返回首页才算部署成功。
i=1
while [ "$i" -le 30 ]; do
  if curl --fail --silent --show-error http://127.0.0.1:18081/ >/dev/null; then
    exit 0
  fi
  i=$((i + 1))
  sleep 2
done

exit 1
