#!/bin/sh

# 任一命令失败或使用未定义变量时立即停止，避免半完成部署继续执行。
set -eu

deploy_path=${1:?deployment path is required}
archive=${2:?release archive is required}
staging=$(mktemp -d)

# shellcheck disable=SC2329  # Invoked by the EXIT trap.
cleanup() {
  rm -rf "$staging"
  rm -f "$archive" /tmp/deploy-backend.sh
}
# 无论成功还是失败，都清理临时发布包和解压目录。
trap cleanup EXIT

# 覆盖线上文件前先完整校验输入和压缩包结构。
test -f "$deploy_path/.env"
test -f "$archive"
tar -tzf "$archive" >/dev/null
tar -xzf "$archive" -C "$staging"
test -f "$staging/dist/ability-re-backend.jar"
test -f "$staging/docker-compose.yml"

mkdir -p "$deploy_path/dist"
cd "$deploy_path"

# 前后端发布共享同一把文件锁，最多等待 5 分钟。
exec 9>"$deploy_path/.deploy.lock"
command -v flock >/dev/null
flock -w 300 9

install -m 644 "$staging/docker-compose.yml" docker-compose.yml
# 先写 .next 再改名，避免复制中断留下半个 JAR。
install -m 644 "$staging/dist/ability-re-backend.jar" dist/ability-re-backend.jar.next
mv -f dist/ability-re-backend.jar.next dist/ability-re-backend.jar

docker compose up -d mysql
docker compose up -d --force-recreate backend

# 最多等待 120 秒，两个健康接口都成功才把发布标记为完成。
i=1
while [ "$i" -le 60 ]; do
  if curl --fail --silent --show-error http://127.0.0.1:18080/actuator/health/readiness >/dev/null &&
     curl --fail --silent --show-error http://127.0.0.1:18080/api/health >/dev/null; then
    exit 0
  fi
  i=$((i + 1))
  sleep 2
done

exit 1
