#!/bin/bash

cd "$KAFKA_USER_DIR"
chmod -R a+rx "$KAFKA_USER_DIR/bin"

case "$1" in
    broker)
        ;;
    zookeeper)
        ;;
    *)
        term.log 'Invalid option passed to startup\n'
        exit 1
        ;;
esac
"${KAFKA_USER_DIR}/bin/kafka-server-start" "${KAFKA_USER_DIR}/etc/kafka/${1}.properties"
