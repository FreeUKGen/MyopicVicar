#!/usr/bin/env bash

# This script calculates record statistics for FreeBMD2
set -uo pipefail
IFS=$'\n\t'

trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[populating record statistics] ${NOW} $@" >&2
}

ROOT=/home/apache/hosts/freebmd2/production
cd $ROOT
umask 0002
sudo -u webserv bundle exec rake RAILS_ENV=production freebmd:count_records --trace
exit


