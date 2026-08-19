#!/usr/bin/env bash

set -euo pipefail

log() {
  echo "[compose_setup]" "$@"
}

mkdir -p public/system tmp/users/testuser4 tmp/mongo_import

copy_seed_files() {
  local source_dir="$1"
  local target_dir="$2"

  if [ -d "$source_dir" ] && ! find "$target_dir" -mindepth 1 -print -quit | grep -q .; then
    log "Installing seed files into $target_dir"
    cp "$source_dir"/* "$target_dir"/
  fi
}

copy_seed_files dev/docker/seed-data/mongo_import tmp/mongo_import
copy_seed_files dev/docker/seed-data/users/testuser4 tmp/users/testuser4

copy_config() {
  local source_file="$1"
  local target_file="$2"

  if [ ! -f "$target_file" ] || [ "${FORCE_CONFIG:-false}" = "true" ]; then
    log "Installing $target_file"
    cp "$source_file" "$target_file"
  fi
}

copy_config dev/docker/compose-config/database.yml config/database.yml
copy_config dev/docker/compose-config/mongoid.yml config/mongoid.yml
copy_config dev/docker/compose-config/mongo_config.yml config/mongo_config.yml
copy_config dev/docker/compose-config/errbit.yml config/errbit.yml
copy_config dev/docker/compose-config/freeukgen_application.yml config/freeukgen_application.yml
copy_config dev/docker/compose-config/secrets.yml config/secrets.yml

log "Waiting for MariaDB"
until mysqladmin ping -h mysql -ufreereg2 -pfreereg2 --silent; do
  sleep 2
done

log "Waiting for MongoDB"
until timeout 2 bash -c "cat < /dev/null > /dev/tcp/${MONGO_HOST:-mongo}/${MONGO_PORT:-27017}"; do
  sleep 2
done

log "Installing gems"
bundle check || bundle install --jobs=8 --retry=3

log "Running FreeREG setup script with LOAD_DATA=${LOAD_DATA:-none}"
bash dev/docker/fugsetup_all.sh
