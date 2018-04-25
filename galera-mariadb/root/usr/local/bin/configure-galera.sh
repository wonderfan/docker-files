#! /bin/bash

# Copyright 2016 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script writes out a mysql galera config using a list of newline seperated
# peer DNS names it accepts through stdin.

CFG=/etc/mysql/my.cnf

function join {
    local IFS="$1"; shift; echo "$*";
}

HOSTNAME=$(hostname)
echo HOSTNAME is $HOSTNAME
# Parse out cluster name, from service name:
CLUSTER_NAME="$(hostname -f | cut -d'.' -f2)"
echo CLUSTER_NAME is $CLUSTER_NAME

while read -ra LINE; do
    if [[ "${LINE}" == *"${HOSTNAME}"* ]]; then
        MY_NAME=$LINE
    fi
    PEERS=("${PEERS[@]}" $LINE)
done
echo MY_NAME is $MY_NAME
echo PEERS is $PEERS

if [ "${#PEERS[@]}" = 1 ]; then
    WSREP_CLUSTER_ADDRESS=""
else
    WSREP_CLUSTER_ADDRESS=$(join , "${PEERS[@]}")
fi
echo WSREP_CLUSTER_ADDRESS is $WSREP_CLUSTER_ADDRESS

sed -i -e "s|^wsrep_node_address=.*$|wsrep_node_address=${MY_NAME}|" ${CFG}
sed -i -e "s|^wsrep_cluster_name=.*$|wsrep_cluster_name=${CLUSTER_NAME}|" ${CFG}
sed -i -e "s|^wsrep_cluster_address=.*$|wsrep_cluster_address=gcomm://${WSREP_CLUSTER_ADDRESS}|" ${CFG}

cp ${CFG} /var/lib/mysql/mysql.cnf
cat ${CFG} | grep wsrep

# don't need a restart, we're just writing the conf in case there's an
# unexpected restart on the node.