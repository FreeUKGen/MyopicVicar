#!/usr/bin/env /usr/local/bin/bash
# note: on ubuntu dev machine, needed to set up a link to /bin/bash

# This script updates the freecen2 production database
# It just rsyncs the data from FC1 to FC2 on the local machine before
# running the rake task that updates the database.
#
# To manually rsync the data from freecen production server to test2 server:
#  ssh -A user@test2host
#  rsync -avz --delete user@productionhost:/raid/freecen/fixed /raid/freecen2/freecen1/
#  rsync -avz --delete user@productionhost:/raid/freecen/pieces /raid/freecen/
#  rsync -avz user@productionhost:/home/apache/hosts/freecen/status/db-stats /raid/freecen2/freecen1/
#  check permisions and ownership

set -uo pipefail
IFS=$'\n\t'

HN=$( hostname -s )
trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[update_freecen2_production.sh][${HN}] ${NOW} $@" >&2
}

#fail() {
#  sudo /root/bin/searchctl.sh enable
#  trace "FATAL $@"
#  exit 1
#}
#trap fail ERR

FC1_DATA=/raid/freecen
FC1_STAT_FILE=/home/apache/hosts/freecen/status/db-stats
FC2_DATA=/raid/freecen2
LOG_DIR=${FC2_DATA}/log
APP_ROOT=/home/apache/hosts/freecen2/production
WEB_USER=webserv
BUNDLE=bundle
#different directories on development machine (pass in "development" as arg 1)
if [ $# -ge 1 ] && [ $1 == "development" ]; then
  trace "***NOTICE: using local development machine directory structure"
  FC1_DATA=~/freeUKGEN/data/update_test_fc1
  FC1_STAT_FILE=/home/apache/hosts/freecen/status/db-stats #ok if doesn't exist
  FC2_DATA=~/freeUKGEN/data/update_test_fc2
  LOG_DIR=/tmp
  APP_ROOT=~/freeUKGEN/MyopicVicar
  WEB_USER=$( whoami )
  BUNDLE=~/.rvm/gems/ruby-2.2.5/bin/bundle
fi

if [[ ! -d ${FC1_DATA} ]] ; then
  trace "***ERROR: couldn't find FC1 source directory for rsync (${FC1_DATA})"
  exit 1
fi
cd ${APP_ROOT}
umask 0002

# create target directories if absent
if [[ ! -d ${FC2_DATA}/freecen1 ]] ; then
  trace "${FC2_DATA}/freecen1 doesn't exist, creating"
  mkdir -p ${FC2_DATA}/freecen1
fi
if [[ ! -d ${LOG_DIR} ]] ; then
  trace "${LOG_DIR} doesn't exist, creating"
  mkdir -p ${LOG_DIR}
fi

# rsync the FC2 data from FC1 data directories
trace "doing rsync of FreeCen1 metadata (ctyPARMS.DAT) files into FreeCen2"
sudo -u ${WEB_USER} rsync -avz --delete ${FC1_DATA}/fixed ${FC2_DATA}/freecen1/ 2>${LOG_DIR}/rsync.errors | egrep -v '(^receiving|^sending|^sent|^total|^cannot|^deleting|^$|/$)' > ${LOG_DIR}/freecen1.delta

trace "doing rsync of FreeCen1 validated piece (.VLD) files into FreeCen2"
sudo -u ${WEB_USER} rsync -avz --delete ${FC1_DATA}/pieces ${FC2_DATA}/freecen1/ 2>${LOG_DIR}/rsync.errors | egrep -v '(^receiving|^sending|^sent|^total|^cannot|^deleting|^$|/$)' >> ${LOG_DIR}/freecen1.delta

if [[ -f ${FC1_STAT_FILE} ]] ; then
  trace "doing rsync of FreeCen1 db-status file into FreeCen2"
  sudo -u ${WEB_USER} rsync -avz ${FC1_STAT_FILE} ${FC2_DATA}/freecen1/ 2>${LOG_DIR}/rsync.errors | egrep -v '(^receiving|^sending|^sent|^total|^cannot|^deleting|^$|/$)' >> ${LOG_DIR}/freecen1.delta
else
  trace "***WARNING: not doing rsync of status file because ${FC1_STAT_FILE} not found"
fi

#Do we need to disable/enable searches below using /root/bin/searchctl.sh?
#It was in the FreeReg2 script, but I don't think we need it. If we do, then
#uncomment the lines and also uncomment the fail()/trap above.

#trace "disable of searches"
#sudo /root/bin/searchctl.sh disable
trace "running rake task to update the freecen database"
sudo -u ${WEB_USER} ${BUNDLE} exec rake RAILS_ENV=production build:freecen_update_from_FC1["${FC2_DATA}/freecen1/fixed","${FC2_DATA}/freecen1/pieces"] --trace
trace "running rake task to update the places cache"
sudo -u ${WEB_USER} ${BUNDLE} exec rake RAILS_ENV=production foo:refresh_places_cache["false"] --trace

#trace "re enable searches"
#sudo /root/bin/searchctl.sh enable
trace "finished"
exit
