#!/usr/bin/env bash

# This script calculates statistics for F2
set -uo pipefail
IFS=$'\n\t'

ROOT=/home/apache/hosts/freecen2/production
cd $ROOT
umask 0002

trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[calculate_search_statistics] ${NOW} $@" >&2
}
sudo -u webserv bundle exec rake RAILS_ENV=production freecen:calculate_search_queries --trace


trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[calculate_site_statistics] ${NOW} $@" >&2
}

sudo -u webserv bundle exec rake RAILS_ENV=production freecen:calculate_site_statistics --trace


trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[calculate_freecen2_contents] ${NOW} $@" >&2
}
sudo -u webserv bundle exec rake RAILS_ENV=production freecen:calculate_contents --trace

trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[calculate_unique_names] ${NOW} $@" >&2
}
sudo -u webserv bundle exec rake RAILS_ENV=production freecen:Freecen2PlaceExtractUniqueNames[1] --trace

exit


