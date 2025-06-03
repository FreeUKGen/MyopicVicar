#!/usr/bin/env bash
set -uo pipefail
IFS=$'\n\t'

ROOT=/home/apache/hosts/freereg2/production
cd $ROOT
umask 0002

trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[reprocess_county_records] ${NOW} $@" >&2
}
sudo -u webserv bundle exec rake RAILS_ENV=production freereg:reprocess_batches_for_a_county[CON]
exit
