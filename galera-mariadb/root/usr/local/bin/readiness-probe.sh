#!/bin/bash

MYSQL_USER="readinessProbe"
MYSQL_PASS="readinessProbe"
MYSQL_HOST="localhost"

echo "Checking readiness - $(date)"
mysql --protocol=socket --socket=/var/run/mysql/mysql.sock -u${MYSQL_USER} -p${MYSQL_PASS} -h${MYSQL_HOST} -e"SHOW DATABASES;"

if [ $? -ne 0 ]; then
  exit 1
else
  exit 0
fi