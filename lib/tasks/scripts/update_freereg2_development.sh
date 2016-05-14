#!/usr/bin/env bash

# This script updates the freereg2 development database
set -uo pipefail
IFS=$'\n\t'

trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[update-freereg2_production_database] ${NOW} $@" >&2
}

fail() {
  trace "FATAL $@"
  exit 1
}
trap fail ERR

DATA_ROOT=/raid/freereg2
FREEREG1=${DATA_ROOT}/freereg1/users
FREEREG1_DELTA=${DATA_ROOT}/tmp
ROOT=/home/apache/hosts/freereg2/production
LOG_DIR=${DATA_ROOT}/log
umask 0002

if [[ ! -d ${FREEREG1} ]] ; then
  # create target if absent (or we could call fail() to stop here)
  trace "${FREEREG1} doesn't exist, creating"
  mkdir -p ${FREEREG1}
fi
if [[ ! -d ${FREEREG1_DELTA} ]] ; then
  # create target if absent (or we could call fail() to stop here)
  trace "${FREEREG1_DELTA} doesn't exist, creating"
  mkdir -p ${FREEREG1_DELTA}
fi


trace "enforcing ownership on ${DATA_ROOT}"

cd ${ROOT}
trace "update of the database2"
sudo -u webserv bundle exec rake RAILS_ENV=production build:freereg_new_update[create_search_records,waiting,no_force,a-9] --trace
trace "delete of entries and records for removed batches"
sudo -u webserv bundle exec rake RAILS_ENV=production delete_file[0] --trace

trace "finished"
exit


