#!/usr/bin/env bash

# This script calculates search statistics for F2
set -uo pipefail
IFS=$'\n\t'

trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[freecen2_nightly_cleanup] ${NOW} $@" >&2
}

ROOT=/home/apache/hosts/freecen2/production
cd $ROOT
umask 0002
trace "process delete_list"
sudo -u webserv bundle exec rake RAILS_ENV=production delete_freecen_csv_file_no_sleep[0] --trace
trace "delete older log and txt filea"
sudo -u webserv bundle exec rake RAILS_ENV=production delete_old_txt_and_log_files --trace
exit


