#!/usr/bin/env bash

# This script copies the db-stats file needed to display freecen2 graphs
# from /home/aapache/hosts/freecen/status/db-stats
# to /raid/freecen2/freecen1/
set -uo pipefail
IFS=$'\n\t'

trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[copy_fc1_stats_to_fc2_for_graph] ${NOW} $@" >&2
}

ROOT=/home/apache/hosts/freecen2/production
cd $ROOT
umask 0002
sudo -u webserv rsync -a /home/apache/hosts/freecen/status/db-stats /raid/freecen2/freecen1/
exit
