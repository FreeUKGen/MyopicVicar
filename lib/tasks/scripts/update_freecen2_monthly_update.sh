# This script updates the freecen2 production database.
# It rsyncs the data from FC1 to FC2 on the local machine (unless 'nosync' is
# passed in as argument 1 or 2 on the command line) before
# running the rake tasks that:
#  1) update the database
#  2) initialize geolocation lat/long for new subplaces that aren't set
#  3) update the places cache
#
#
# To manually rsync the data from freecen production server to test2 server:
#  ssh -A user@host
# rsync -avz --delete dougkdev@colobus.freebmd.org.uk:/raid/freecen/fixed /raid/freecen2/freecen1/
# rsync -avz --delete dougkdev@colobus.freebmd.org.uk:/raid/freecen/pieces /raid/freecen2/freecen1/
# rsync -avz --delete dougkdev@colobus.freebmd.org.uk:/home/apache/hosts/freecen/status/db-stats /raid/freecen2/freecen1/

set -uo pipefail
IFS=$'\n\t'

HN=$( hostname -s )
trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[update_freecen2_production.sh][${HN}] ${NOW} $@" >&2
}

current_user="$USER"

FC1_DATA="$current_user"@colobus.freebmd.org.uk:/raid/freecen
FC1_STAT_FILE=current_user@colobus.freebmd.org.uk:/home/apache/hosts/freecen/status/db-stats
FC2_DATA=/raid/freecen2/
LOG_DIR=${FC2_DATA}/log
APP_ROOT=/home/apache/hosts/freecen2/production
UPDATE_RUNNING_STATUS_FILE=${APP_ROOT}/tmp/fc_update_processing.txt #fc_update_processor_status_file value in config/mongo_config.yml needs to match
GEOLOCATION_FILE=${APP_ROOT}/test_data/Place_and_church_name_resources/places_from_public_domain_data.csv
WEB_USER=webserv
BUNDLE=bundle

# if another update process is currently running, exit early
if [[ -f ${UPDATE_RUNNING_STATUS_FILE} ]] ; then
  trace "***ERROR: There seems to be an update process already running because file '${UPDATE_RUNNING_STATUS_FILE}' exists. Calling exit now to avoid interfering with the other update process."
  exit 1
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

DO_RSYNC=true
if [ $# -ge 1 ] && [ "$1" == "nosync" ]; then
  DO_RSYNC=false
elif [ $# -ge 2 ] && [ "$2" == "nosync" ]; then
  DO_RSYNC=false
fi

# rsync the FC2 data from FC1 data directories
if [ "$DO_RSYNC" == true ] ; then
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

else
  trace "***WARNING: not doing rsync because 'nosync' option was passed into script"
fi

fail() {
  sudo /root/bin/searchctl.sh enable
  trace "FATAL $@"
  exit 1
}

if [[ -f /root/bin/searchctl.sh ]] ; then
  trap fail ERR
  trace "disable searches while update script runs"
  sudo /root/bin/searchctl.sh disable
else
  trace "***WARNING: /root/bin/searchctl.sh not found! not disabling searches"
fi

trace "running rake task to update the freecen database"
sudo -u ${WEB_USER} ${BUNDLE} exec rake RAILS_ENV=production freecen_update_from_FC1["${FC2_DATA}/freecen1/fixed","${FC2_DATA}/freecen1/pieces"] > "${LOG_DIR}/update_manual_rake_task_20170620_1942BST.log" 2>&1 < /dev/null &

trace "running rake task to initialize pieces subplace geolocation for new pieces"
sudo -u ${WEB_USER} ${BUNDLE} exec rake RAILS_ENV=production  initialize_pieces_subplaces_geo[${GEOLOCATION_FILE},true] --trace

trace "running rake task to initialize places geolocation based on subplaces, only for those not already set"
sudo -u ${WEB_USER} ${BUNDLE} exec rake RAILS_ENV=production initialize_places_geo[${GEOLOCATION_FILE},true,use_subplaces] --trace

trace "running rake task to update the places cache"
sudo -u ${WEB_USER} ${BUNDLE} exec rake RAILS_ENV=production foo:refresh_places_cache["false"] --trace

if [[ -f /root/bin/searchctl.sh ]] ; then
  trace "re-enable searches"
  sudo /root/bin/searchctl.sh enable
fi

trace "finished"
exit