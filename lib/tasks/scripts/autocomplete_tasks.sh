#!/usr/bin/env bash

# This script calculates search statistics for F2
set -uo pipefail
IFS=$'\n\t'

trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[populating unique names] ${NOW} $@" >&2
}

ROOT=/home/apache/hosts/freebmd2/production
cd $ROOT
umask 0002
sudo -u webserv bundle exec rake RAILS_ENV=production unique_surnames --trace
sudo -u webserv bundle exec rake RAILS_ENV=production unique_individual_forenames --trace
exit


