#!/usr/bin/env bash

# This script updates the freereg2 production database
set -uo pipefail
IFS=$'\n\t'

trace() {
+  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
+  echo "[update-freereg2_production_database] ${NOW} $@" >&2
}

fail() {
  sudo /root/bin/searchctl.sh enable
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
trace "disable of searches"
sudo /root/bin/searchctl.sh disable
cd ${ROOT}
trace "doing rsync of freereg1 data into freereg2"
sudo -u webserv rsync  -avz  --delete --exclude '.attic' --exclude '.errors' --exclude '.warnings' --exclude '.uDetails' /raid/freereg/users/ ${FREEREG1}/ 2>${LOG_DIR}/rsync.errors | egrep -v '(^receiving|^sending|^sent|^total|^cannot|^deleting|^$|/$)' > ${LOG_DIR}/freereg1.delta
trace "update of the database2"
sudo -u webserv bundle exec rake RAILS_ENV=production build:freereg_update[a-9,search_records,delta] --trace
trace "delete of entries and records for removed batches"
sudo -u webserv bundle exec rake RAILS_ENV=production build:delete_entries_records_for_removed_batches --trace
trace "re enable searches"
sudo /root/bin/searchctl.sh enable
trace "finished"
exit


