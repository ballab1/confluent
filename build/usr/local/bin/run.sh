#!/bin/bash
cd "$KAFKA_USER_DIR"
chmod -R a+rx "$KAFKA_USER_DIR/bin"

if [ $# -eq 0 ] || [ $1 = 'broker' ]; then
    bin/kafka-server-start.sh config/server.properties
elif [ $1 = 'zookeeper' ]; then
    bin/zookeeper-server-start.sh config/zookeeper.properties
fi
