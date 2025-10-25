#!/usr/bin/env bash

# This script calculates search statistics for F2
set -uo pipefail
IFS=$'\n\t'

trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[update database] ${NOW} $@" >&2
}

ROOT=/home/apache/hosts/freebmd2/production
FILE_PATH=/home/apache/hosts/freebmd/status/current_db
cd $ROOT
umask 0002
sudo -u webserv bundle exec rake RAILS_ENV=production all_tasks:run_all[production,FILE_PATH] --trace
exit