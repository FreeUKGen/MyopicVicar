#!/usr/bin/env bash

# This script calculates search statistics for F2
set -uo pipefail
IFS=$'\n\t'

trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[extract_unique_names] ${NOW} $@" >&2
}

ROOT=/home/apache/hosts/freereg2/production
cd $ROOT
umask 0002
sudo -u webserv bundle exec rake RAILS_ENV=production reports:extract_collection_unique_names[0] --trace
exit


