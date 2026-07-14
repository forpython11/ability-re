#!/bin/sh

set -eu

deploy_path=${1:?deployment path is required}
archive=${2:?release archive is required}

cleanup() {
  rm -f "$archive" /tmp/deploy.sh
}
trap cleanup EXIT

file_hash() {
  if [ -f "$1" ]; then
    sha256sum "$1" | awk '{print $1}'
  else
    printf 'missing\n'
  fi
}

dir_hash() {
  if [ -d "$1" ]; then
    find "$1" -type f -exec sha256sum {} \; | sort | sha256sum | awk '{print $1}'
  else
    printf 'missing\n'
  fi
}

service_running() {
  container_id=$(docker compose ps -q "$1" 2>/dev/null || true)
  [ -n "$container_id" ] && [ "$(docker inspect -f '{{.State.Running}}' "$container_id" 2>/dev/null || true)" = "true" ]
}

test -f "$deploy_path/.env"
test -f "$archive"
tar -tzf "$archive" >/dev/null

mkdir -p "$deploy_path"
cd "$deploy_path"

old_backend_hash=$(file_hash dist/ability-re-backend.jar)
old_frontend_hash=$(dir_hash dist/frontend)
old_compose_hash=$(file_hash docker-compose.yml)
old_nginx_hash=$(file_hash nginx.conf)

tar -xzf "$archive" -C "$deploy_path"

new_backend_hash=$(file_hash dist/ability-re-backend.jar)
new_frontend_hash=$(dir_hash dist/frontend)
new_compose_hash=$(file_hash docker-compose.yml)
new_nginx_hash=$(file_hash nginx.conf)

docker compose up -d mysql

backend_changed=false
frontend_changed=false

if [ "$old_backend_hash" != "$new_backend_hash" ] ||
   [ "$old_compose_hash" != "$new_compose_hash" ] ||
   ! service_running backend; then
  backend_changed=true
fi

if [ "$old_frontend_hash" != "$new_frontend_hash" ] ||
   [ "$old_nginx_hash" != "$new_nginx_hash" ] ||
   [ "$old_compose_hash" != "$new_compose_hash" ] ||
   ! service_running frontend; then
  frontend_changed=true
fi

if [ "$backend_changed" = true ]; then
  docker compose up -d --force-recreate backend
else
  docker compose up -d --no-recreate backend
fi

if [ "$frontend_changed" = true ]; then
  docker compose up -d --force-recreate frontend
else
  docker compose up -d --no-recreate frontend
fi

i=1
while [ "$i" -le 60 ]; do
  if curl --fail --silent --show-error http://127.0.0.1:18081/ >/dev/null &&
     curl --fail --silent --show-error http://127.0.0.1:18081/api/health >/dev/null; then
    exit 0
  fi
  i=$((i + 1))
  sleep 2
done

exit 1
