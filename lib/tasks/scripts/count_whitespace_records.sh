#!/usr/bin/env bash

set -uo pipefail
IFS=$'\n\t'

trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[count whitespace records] ${NOW} $@" >&2
}

ROOT=/home/apache/hosts/freereg2/production
cd $ROOT
umask 0002
  sudo -u webserv bundle exec rake RAILS_ENV=production count_whitespaces_in_search_record_names
exit
