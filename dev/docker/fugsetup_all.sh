#!/usr/bin/env bash

set -euo pipefail

log() {
  echo "[fugsetup]" "$@"
}

load_data="${LOAD_DATA:-none}"
mongo_host="${MONGO_HOST:-mongo}"
mongo_port="${MONGO_PORT:-27017}"
import_dir="${MYOPIC_VICAR_IMPORT_DIR:-./tmp/mongo_import}"

mongo_import() {
  local collection="$1"
  local file="${import_dir}/${collection}.json"

  if [ ! -f "$file" ]; then
    log "Missing Mongo seed file: $file"
    exit 1
  fi

  log "Importing Mongo collection: $collection"
  if command -v mongoimport >/dev/null 2>&1; then
    mongoimport \
      --host "$mongo_host" \
      --port "$mongo_port" \
      --db myopic_vicar_development \
      --collection "$collection" \
      --file "$file"
  else
    ruby dev/docker/compose_mongo_import.rb \
      myopic_vicar_development \
      "$collection" \
      "$file"
  fi
}

load_mongo_seed_data() {
  local collections=(
    places
    churches
    counties
    countries
    denominations
    registers
    syndicates
    userid_details
    emendation_rules
    emendation_types
  )

  local collection
  for collection in "${collections[@]}"; do
    mongo_import "$collection"
  done

  log "Mongo reference data import complete"
}

load_application_seed_data() {
  log "Building FreeREG records from the runtime CSV files"
  bundle exec rake build:freereg_from_files[,,,,1/2/3/4/5/6/7/8/9/10/11/12/13/14/15/16/17/18/19,27017] --trace

  log "Connecting UserID details to Refinery users"
  bundle exec rake freeuk:add_user --trace

  log "Loading emendations"
  bundle exec rake load_emendations --trace

  log "Creating FreeREG entries and search records"
  bundle exec rake build:recommence_freereg_new_update[create_search_records,range,force_rebuild,a-9] --trace

  log "Creating FreeREG search indexes"
  bundle exec rails runner 'SearchRecord::REG_PLACE_INDEXES.merge(SearchRecord::REG_CHAPMAN_INDEXES).merge(SearchRecord::REG_BASIC_INDEXES).each { |name, fields| SearchRecord.collection.indexes.create_one(fields.map { |field| [field, 1] }.to_h, name: name, background: true) }'

  log "Refreshing the places cache"
  bundle exec rake foo:refresh_places_cache

  log "Calculating transcription content"
  bundle exec rake freereg:calculate_freereg_content --trace

  log "Application seed data import complete"
}

log "LOAD_DATA=$load_data"

case "$load_data" in
  none)
    log "No seed data requested"
    ;;
  mongo)
    load_mongo_seed_data
    ;;
  data)
    load_application_seed_data
    ;;
  *)
    log "Unsupported LOAD_DATA value: $load_data"
    log "Supported values: none, mongo, data"
    exit 64
    ;;
esac
