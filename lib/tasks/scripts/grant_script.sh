#!/bin/bash

ENVIRONMENT="production"
CONFIG_FILE="config/freebmd_database.yml"

MYSQL_USER=$(yq e ".${ENVIRONMENT}.username" $CONFIG_FILE)
MYSQL_PASSWORD=$(yq e ".${ENVIRONMENT}.password" $CONFIG_FILE)
#MYSQL_HOST=$(yq e ".${ENVIRONMENT}.host" $CONFIG_FILE)

mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -N -B -e "
SELECT CONCAT(
    'GRANT INSERT ON \`', SCHEMA_NAME, '\`.Postems TO ''freebmd2''@''localhost'';'
)
FROM information_schema.schemata
WHERE SCHEMA_NAME LIKE 'bmd\_%';
" | mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD"