#!/bin/bash
set -xe

echo "Starting entrypoint at $(date)" >> /var/lib/mysql/entrypoint.log

# Check if the container runs in Kubernetes
if [ -z "$POD_NAMESPACE" ]; then
	# Single container runs in docker
	echo "POD_NAMESPACE not set, spin up single node"
else
	# Is running in Kubernetes, so find all other pods
	# belonging to the namespace
	echo "Galera: Finding peers"
	K8S_SVC_NAME=$(hostname -f | cut -d"." -f2)
	echo "Using service name: ${K8S_SVC_NAME}"
	# --on-change is not used so this chart can not deal with peer changes
	/usr/local/bin/peer-finder -on-start="/usr/local/bin/configure-galera.sh" -service=${K8S_SVC_NAME}
fi

# We assume that mysql needs to be setup if this directory is not present
if [ ! -d "/var/lib/mysql/mysql" ]; then
	echo "Configure MariaDB for first run"
	echo "Configure MariaDB for first run at $(date)" >> /var/lib/mysql/entrypoint.log
	/usr/local/bin/configure-mariadb.sh
else
	echo "MariaDB already configured"
	echo "MariaDB already configured at $(date)" >> /var/lib/mysql/entrypoint.log
fi

# Create the cluster if its the first node
echo "Create the Galera cluster and run MariaDB"
mysqld