#!/usr/bin/env bash

set -uo pipefail
IFS=$'\n\t'

trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[clean up processed record] ${NOW} $@" >&2
}

ROOT=/home/apache/hosts/freereg2/production
cd $ROOT
umask 0002
sudo -u webserv bundle exec rake RAILS_ENV=production freereg:clean_up_processed_batch[STS]
exit