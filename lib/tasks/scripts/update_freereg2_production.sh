#!/usr/bin/env bash

# This script updates the freereg2 production database
set -uo pipefail
IFS=$'\n\t'

trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[update-freereg2_production_database] ${NOW} $@" >&2
}

fail() {
  sudo /root/bin/searchctl.sh enable
  trace "FATAL $@"
  exit 1
}
trap fail ERR

DATA_ROOT=/raid/freereg2
FREEREG2=${DATA_ROOT}/users
FREEREG2_DELTA=${DATA_ROOT}/log
ROOT=/home/apache/hosts/freereg2/production
LOG_DIR=${DATA_ROOT}/log
PROCESS=${LOG_DIR}/processing_delta
umask 0002
if [[ ! -d ${FREEREG2} ]] ; then
  # create target if absent (or we could call fail() to stop here)
  trace "${FREEREG2} doesn't exist, creating"
  mkdir -p ${FREEREG2}
fi
if [[ ! -d ${FREEREG2_DELTA} ]] ; then
  # create target if absent (or we could call fail() to stop here)
  trace "${FREEREG2_DELTA} doesn't exist, creating"
  mkdir -p ${FREEREG2_DELTA}
fi
if [[ ! -e ${PROCESS} ]] ; then
  # create target if absent (or we could call fail() to stop here)
  trace "${PROCESS} doesn't exist, creating"
  touch ${PROCESS}
fi
trace "disable of searches"
sudo /root/bin/searchctl.sh disable
cd ${ROOT}
trace "doing rsync of freereg1 data into freereg2"
sudo -u webserv rsync  -avz  --exclude '.attic' --exclude '.errors' --exclude '.warnings' --exclude '.uDetails' /raid/freereg/users/ ${FREEREG2}/ 2>${LOG_DIR}/rsync.errors | egrep -v '(^receiving|^sending|^sent|^total|^cannot|^deleting|^$|/$)' > ${LOG_DIR}/freereg1.delta
trace "update of the database2"
sudo -u webserv bundle exec rake RAILS_ENV=production build:freereg_update[a-9,search_records,delta] --trace
sudo -u webserv bundle exec rake RAILS_ENV=production build:freereg_update[a-9,search_records,process] --trace
trace "delete of entries and records for removed batches"
sudo -u webserv bundle exec rake RAILS_ENV=production build:delete_entries_records_for_removed_batches --trace
trace "re enable searches"
sudo /root/bin/searchctl.sh enable
trace "finished"
exit


