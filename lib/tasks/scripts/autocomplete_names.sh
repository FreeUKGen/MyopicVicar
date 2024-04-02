#!/usr/bin/env bash

# This script populates the names for autocomplete
set -uo pipefail
IFS=$'\n\t'

trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[extract_names_for_autocomplete] ${NOW} $@" >&2
}

ROOT=/home/apache/hosts/freebmd2/production
cd $ROOT
umask 0002
sudo -u webserv bundle exec rake RAILS_ENV=production unique_individual_forenames --trace
sudo -u webserv bundle exec rake RAILS_ENV=production unique_surnames --trace
exit
