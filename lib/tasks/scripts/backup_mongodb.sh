#!/usr/bin/env bash

# This script backups mongodb
set -uo pipefail
IFS=$'\n\t'

trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[backup mongodb] ${NOW} $@" >&2
}

TODAY=$(date '+%Y%m%d')
DATA_ROOT=/raid/freereg2
FREEREG2=${DATA_ROOT}/back_up_${TODAY}
ROOT=/home/apache/hosts/freereg2/production
HOST="mongo5.freeukgen.org.uk:27017"
BASE="freereg_2021"
cd $ROOT
umask 0002
if [[ ! -d ${FREEREG2} ]] ; then
  # create target if absent (or we could call fail() to stop here)
  trace "${FREEREG2} doesn't exist, creating"
  mkdir -p ${FREEREG2}
fi
collections = mongo $BASE --quiet --eval "db.getCollectionNames().join(' ')"
for collection in $collections
  do
    mongoexport --ssl --sslAllowInvalidCertificates --host $HOST --db $BASE --collection $collection --out ${FREEREG2}/${collection}.json
  done
exit