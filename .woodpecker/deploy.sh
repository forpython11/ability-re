#!/bin/sh

set -eu

deploy_path=${1:?deployment path is required}
archive=${2:?release archive is required}

cleanup() {
  rm -f "$archive" /tmp/deploy.sh
}
trap cleanup EXIT

test -f "$deploy_path/.env"
test -f "$archive"
tar -tzf "$archive" >/dev/null

mkdir -p "$deploy_path"
tar -xzf "$archive" -C "$deploy_path"

cd "$deploy_path"
docker compose up -d mysql
docker compose up -d --force-recreate backend frontend

for attempt in 1 2 3 4 5 6 7 8 9 10 11 12; do
  if curl --fail --silent --show-error http://127.0.0.1:18081/ >/dev/null &&
     curl --fail --silent --show-error http://127.0.0.1:18081/api/health >/dev/null; then
    exit 0
  fi
  sleep 5
done

exit 1
