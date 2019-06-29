#!/bin/bash
cd "$KAFKA_USER_DIR"
chmod -R a+rx "$KAFKA_USER_DIR/bin"

case "$1" in
    broker)
        "${KAFKA_USER_DIR}/bin/kafka-server-start" "${KAFKA_USER_DIR}/etc/kafka/server.properties"
        ;;
    zookeeper)
        "${KAFKA_USER_DIR}/bin/zookeeper-server-start" "${KAFKA_USER_DIR}/etc/kafka/zookeeper.properties"
        ;;
    *)
        term.log 'Invalid option passed to startup\n'
        ;;
esac
