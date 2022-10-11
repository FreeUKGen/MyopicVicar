#!/usr/bin/env bash

# This script archives site statistics for F2
set -uo pipefail
IFS=$'\n\t'

trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[archive site statistics] ${NOW} $@" >&2
}

ROOT=/home/apache/hosts/freecen2/production
cd $ROOT
umask 0002
sudo -u webserv bundle exec rake RAILS_ENV=production freecen:archive_site_statistics --trace
exit