#!/bin/bash

# Set MySQL credentials
ENVIRONMENT="production"
YAML_FILE="config/freebmd_database.yml"

MYSQL_USER=$(yq e ".${ENVIRONMENT}.username" $YAML_FILE)
MYSQL_PASSWORD=$(yq e ".${ENVIRONMENT}.password" $YAML_FILE)


# Find the latest bmd_<epoch> database
LATEST_DB=$(mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -h"$MYSQL_HOST" -N -B -e "SHOW DATABASES LIKE 'bmd\_%';" \
  | grep -E '^bmd_[0-9]+$' \
  | awk -F_ '{print $2"\t"$0}' \
  | sort -k1,1nr \
  | head -n1 \
  | cut -f2)

if [ -z "$LATEST_DB" ]; then
  echo "No bmd_<epoch> databases found."
  exit 1
fi

echo "Latest database: $LATEST_DB"

# Update or create YAML file
if [ -f "$YAML_FILE" ]; then
  # Replace existing database: line or add if not present
  if grep -q '^database:' "$YAML_FILE"; then
    sed -i "s|^database:.*|database: $LATEST_DB|" "$YAML_FILE"
  else
    echo "database: $LATEST_DB" >> "$YAML_FILE"
  fi
else
  echo "database: $LATEST_DB" > "$YAML_FILE"
fi

echo "Updated $YAML_FILE with database: $LATEST_DB"