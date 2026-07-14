#!/bin/sh

set -eu

deploy_path=${1:?deployment path is required}
archive=${2:?release archive is required}
staging=$(mktemp -d)

# shellcheck disable=SC2329  # Invoked by the EXIT trap.
cleanup() {
  rm -rf "$staging"
  rm -f "$archive" /tmp/deploy-backend.sh
}
trap cleanup EXIT

test -f "$deploy_path/.env"
test -f "$archive"
tar -tzf "$archive" >/dev/null
tar -xzf "$archive" -C "$staging"
test -f "$staging/dist/ability-re-backend.jar"
test -f "$staging/docker-compose.yml"

mkdir -p "$deploy_path/dist"
cd "$deploy_path"

exec 9>"$deploy_path/.deploy.lock"
command -v flock >/dev/null
flock -w 300 9

install -m 644 "$staging/docker-compose.yml" docker-compose.yml
install -m 644 "$staging/dist/ability-re-backend.jar" dist/ability-re-backend.jar.next
mv -f dist/ability-re-backend.jar.next dist/ability-re-backend.jar

docker compose up -d mysql
docker compose up -d --force-recreate backend

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
