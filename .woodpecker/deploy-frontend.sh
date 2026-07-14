#!/bin/sh

set -eu

deploy_path=${1:?deployment path is required}
archive=${2:?release archive is required}
staging=$(mktemp -d)

# shellcheck disable=SC2329  # Invoked by the EXIT trap.
cleanup() {
  rm -rf "$staging"
  rm -f "$archive" /tmp/deploy-frontend.sh
}
trap cleanup EXIT

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

exec 9>"$deploy_path/.deploy.lock"
command -v flock >/dev/null
flock -w 300 9

install -m 644 "$staging/docker-compose.yml" docker-compose.yml
install -m 644 "$staging/nginx.conf" nginx.conf
rm -rf dist/frontend.next
mkdir -p dist/frontend.next
cp -R "$staging/dist/frontend/." dist/frontend.next/
rm -rf dist/frontend
mv dist/frontend.next dist/frontend

docker compose up -d --no-deps --force-recreate frontend-app frontend

i=1
while [ "$i" -le 30 ]; do
  if curl --fail --silent --show-error http://127.0.0.1:18081/ >/dev/null; then
    exit 0
  fi
  i=$((i + 1))
  sleep 2
done

exit 1
