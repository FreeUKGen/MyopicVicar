#!/usr/bin/env bash

# This script calculates search statistics for F2
set -uo pipefail
IFS=$'\n\t'

trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[delete old messages] ${NOW} $@" >&2
}

ROOT=/home/apache/hosts/freecen2/production
cd $ROOT
umask 0002
sudo -u webserv bundle exec rake RAILS_ENV=production foo:delete_or_archive_old_messages_feedbacks_and_contacts
exit