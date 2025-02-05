#!/usr/bin/env bash

# This script notifies members when a github issue is closed
set -uo pipefail
IFS=$'\n\t'

trace() {
  NOW=$( date +'%Y-%m-%d %H:%M:%S' )
  echo "[notify_github_issue_is_closed] ${NOW} $@" >&2
}

ROOT=/home/apache/hosts/freereg2/production
cd $ROOT
umask 0002
sudo -u webserv bundle exec rake RAILS_ENV=production freereg:notify_issue_closed --trace
exit
