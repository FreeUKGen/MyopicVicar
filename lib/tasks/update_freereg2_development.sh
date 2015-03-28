#!/usr/bin/env bash

# This script updates the freereg2 development database
set -uo pipefail
IFS=$'\n\t'

trace() {
  echo "[update-freereg2_development_database] $@" >&2
}

fail() {
  trace "FATAL $@"
  exit 1
}
trap fail ERR

DATA_ROOT=/raid-test/freereg2
FREEREG1=${DATA_ROOT}/freereg1-test/users
FREEREG1_DELTA=${DATA_ROOT}/tmp
ROOT=/home/apache/hosts/freereg2/MyopicVicar

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
sudo chmod g+ws ${DATA_ROOT}
sudo chown -R webserv:webserv ${DATA_ROOT}

cd ${ROOT}
trace "doing rsync of freereg1 data into freereg2"
sudo rsync -e ssh -avz  --delete --exclude '.attic' --exclude '.errors' --exclude '.warnings' colobus.freebmd.org.uk::regusers/ ${FREEREG1}/ 2>/dev/null | egrep -v '(^receiving|^sent|^total|^cannot|^$|/$)' > ${FREEREG1_DELTA}/freereg1.delta
trace "update of the database2"
bundle exec rake build:freereg_update[a-9,search_records,delta] --trace
trace "delete of entries and records for removed batches"
bundle exec rake build:delete_entries_records_for_removed_batches[100000,1] --trace

trace "setting permssions and enforcing ownership on ${DATA_ROOT}"
sudo chmod g+ws ${DATA_ROOT}
sudo chown -R webserv:webserv ${DATA_ROOT}

trace "finished"
exit


