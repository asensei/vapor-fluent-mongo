#!/bin/bash
set -e

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

if [ ! "$(ls -A /data/db1)" ]; then
    mkdir /data/db1
    mkdir /data/db2
    mkdir /data/db3
fi

echo "STARTING CLUSTER"

mongod --port 27003 --dbpath /data/db3 --replSet $REPLICA_SET_NAME --bind_ip_all &
DB3_PID=$!
mongod --port 27002 --dbpath /data/db2 --replSet $REPLICA_SET_NAME --bind_ip_all &
DB2_PID=$!
mongod --port 27001 --dbpath /data/db1 --replSet $REPLICA_SET_NAME --bind_ip_all &
DB1_PID=$!

waitForMongo 27001
waitForMongo 27002
waitForMongo 27003

echo "CONFIGURING REPLICA SET"
CONFIG="{ _id: '$REPLICA_SET_NAME', members: [{_id: 0, host: 'localhost:27001', priority: 2 }, { _id: 1, host: 'localhost:27002' }, { _id: 2, host: 'localhost:27003' } ]}"
mongosh admin --port 27001 --eval "db.runCommand({ replSetInitiate: $CONFIG })"

waitForMongo 27002
waitForMongo 27003

mongosh admin --port 27001 --eval "db.runCommand({ setParameter: 1, quiet: 1 })"
mongosh admin --port 27002 --eval "db.runCommand({ setParameter: 1, quiet: 1 })"
mongosh admin --port 27003 --eval "db.runCommand({ setParameter: 1, quiet: 1 })"

echo "REPLICA SET ONLINE"

trap 'echo "KILLING"; kill $DB1_PID $DB2_PID $DB3_PID; wait $DB1_PID; wait $DB2_PID; wait $DB3_PID' SIGINT SIGTERM EXIT

wait $DB1_PID
wait $DB2_PID
wait $DB3_PID