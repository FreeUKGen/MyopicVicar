#!/usr/bin/env /usr/local/bin/bash
# copy the freecen1 db-stats file to the /raid/freecen2/freecen1/ directory
# for displaying graphs.

set -uo pipefail
IFS=$'\n\t'

HN=$( hostname -s )
trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[update_freecen2_production.sh][${HN}] ${NOW} $@" >&2
}

FC1_STAT_FILE=/home/apache/hosts/freecen/status/db-stats #fc1_coverage_stats value in config/mongo_config.yml should match
FC2_DATA=/raid/freecen2
LOG_DIR=${FC2_DATA}/log
WEB_USER=webserv

umask 0002

if [[ -f ${FC1_STAT_FILE} ]] ; then
  trace "doing rsync of FreeCen1 db-status file into FreeCen2"
  sudo -u ${WEB_USER} rsync -avz ${FC1_STAT_FILE} ${FC2_DATA}/freecen1/ 2>${LOG_DIR}/rsync.errors | egrep -v '(^receiving|^sending|^sent|^total|^cannot|^deleting|^$|/$)' >> ${LOG_DIR}/freecen1.delta
else
  trace "***WARNING: not doing rsync of status file because ${FC1_STAT_FILE} not found"
fi

trace "copy_fc1_stats_to_fc2_for_graph.sh finished"
exit
