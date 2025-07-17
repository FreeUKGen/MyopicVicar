#!/bin/bash

ENVIRONMENT="production"
YAML_FILE="config/freebmd_database.yml"

# Get MySQL user and password from YAML using awk/grep
MYSQL_USER=$(awk -v env="$ENVIRONMENT" '
  $0 ~ "^"env":" {in_env=1; next}
  in_env && $1 == "username:" {print $2; exit}
' "$YAML_FILE")

MYSQL_PASSWORD=$(awk -v env="$ENVIRONMENT" '
  $0 ~ "^"env":" {in_env=1; next}
  in_env && $1 == "password:" {print $2; exit}
' "$YAML_FILE")

if [[ -z "$MYSQL_USER" || -z "$MYSQL_PASSWORD" ]]; then
  echo "Could not find username or password for environment: $ENVIRONMENT"
  exit 1
fi

# Find the latest bmd_<epoch> database
LATEST_DB=$(mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -N -B -e "SHOW DATABASES LIKE 'bmd\_%';" \
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

# Update or create YAML file (set top-level 'database:' key)
if grep -q '^[[:space:]]*database:' "$YAML_FILE"; then
  # Replace only the first matching line
  awk -v db="$LATEST_DB" '{if (!done && $0 ~ /^[[:space:]]*database:/) {print "database: " db; done=1} else print $0}' "$YAML_FILE" > "${YAML_FILE}.tmp" && mv "${YAML_FILE}.tmp" "$YAML_FILE"
else
  echo "database: $LATEST_DB" >> "$YAML_FILE"
fi

echo "Updated $YAML_FILE with database: $LATEST_DB"