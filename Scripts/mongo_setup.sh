#!/bin/bash
set -e

echo "DOWNLOADING MONGODB"
wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-${MONGODB_VERSION}.tgz

echo "EXTRACTING MONGODB"
tar xfz mongodb-linux-x86_64-${MONGODB_VERSION}.tgz

echo "INSTALLING MONGODB"
export PATH=`pwd`/mongodb-linux-x86_64-${MONGODB_VERSION}/bin:$PATH
mongod --version

REPLICA_SET_NAME=${REPLICA_SET_NAME:=rs0}

function waitForMongo {
    port=$1
    n=0
    until [ $n -ge 20 ]
    do
        mongosh admin --quiet --port $port --eval "db" && break
        n=$[$n+1]
        sleep 2
    done
}

echo "STARTING CLUSTER"

mkdir -p data/db

mongod --port 27017 --dbpath=data/db --replSet $REPLICA_SET_NAME --bind_ip_all &
DB1_PID=$!

waitForMongo 27017

echo "CONFIGURING REPLICA SET"
CONFIG="{ _id: '$REPLICA_SET_NAME', members: [{_id: 0, host: 'localhost:27017', priority: 2 } ]}"
mongosh admin --port 27017 --eval "db.runCommand({ replSetInitiate: $CONFIG })"

mongosh admin --port 27017 --eval "db.runCommand({ setParameter: 1, quiet: 1 })"

echo "REPLICA SET ONLINE"

trap 'echo "KILLING"; kill $DB1_PID; wait $DB1_PID; ' SIGINT SIGTERM EXIT

wait $DB1_PID
