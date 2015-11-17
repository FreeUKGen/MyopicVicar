#!/usr/bin/env bash

# This script calculates search statistics for F2
set -uo pipefail
IFS=$'\n\t'

trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[calculate_search_statistics] ${NOW} $@" >&2
}

ROOT=/home/apache/hosts/freereg2/production
cd $ROOT
umask 0002
sudo -u webserv bundle exec rake RAILS_ENV=production freereg:calculate_site_statistics --trace
exit


