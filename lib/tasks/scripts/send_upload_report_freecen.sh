#!/usr/bin/env bash

# This script sends upload report
set -uo pipefail
IFS=$'\n\t'

trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[send_upload_report] ${NOW} $@" >&2
}

ROOT=/home/apache/hosts/freecen2/production
cd $ROOT
umask 0002
sudo -u webserv bundle exec rake RAILS_ENV=production roles_upload_report --trace
exit
