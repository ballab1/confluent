#!/bin/bash

: ${KAFKA_UID:?"Environment variable 'KAFKA_UID' not defined in '${BASH_SOURCE[0]}'"}

crf.fixupDirectory "$KAFKA_USER_DIR" "$KAFKA_UID"
crf.fixupDirectory "$KAFKA_LOG_DIRS" "$KAFKA_UID"
crf.fixupDirectory "$KAFKA_CONF_DIR" "$KAFKA_UID"

crf.fixupDirectory "$ZOOKEEPER_DATA_DIR" "$KAFKA_UID"
crf.fixupDirectory "$ZOOKEEPER_LOG_DIR" "$KAFKA_UID"
crf.fixupDirectory "$ZOOKEEPER_CONF_DIR" "$KAFKA_UID"

chmod -R a+rx "$KAFKA_USER_DIR/bin"


if [ ${KAFKA_BROKER_ID:-} -gt 0 ]; then
    # Generate the config only if it doesn't exist
    declare config="$KAFKA_CONF_DIR/server.properties"
    if [ -f "$config" ]; then
        lib.updateConfigFromENV 'KAFKA_' "$config"
        [ "${ZOOKEEPER_TIMEOUT:-}" ] && sed -i "s|^zookeeper.connection.timeout.ms=.*$|zookeeper.connection.timeout.ms=$ZOOKEEPER_TIMEOUT|" "$config"
    fi

    printf '\n\nCurrent config: %s\n' "$config"
    cd "$KAFKA_USER_DIR"
    while read ln; do
        printf '    %s\n' "$ln"
    done < <(cat "$config")

    echo
    echo
fi


if [ ${ZOOKEEPER_MY_ID:-} -gt 0 ]; then
    # Write myid only if it doesn't exist
    [ "${ZOOKEEPER_MY_ID:-}" ]  && echo "$ZOOKEEPER_MY_ID" > "$ZOOKEEPER_DATA_DIR/myid"

    # Generate the config only if it doesn't exist
    config="${KAFKA_CONF_DIR}/zookeeper.properties"
    if [ -f "$config" ]; then
        lib.updateConfigFromENV 'ZOOKEEPER_' "$config"
        [ "${ZOOKEEPER_PORT:-}" ]      && sed -i "s|^clientPort=.*$|clientPort=$ZOOKEEPER_PORT|" "$config"
        [ "${ZOOKEEPER_DATA_DIR:-}" ]  && sed -i "s|^dataDir=.*$|dataDir=$ZOOKEEPER_DATA_DIR|" "$config"
        [ "${ZOOKEEPER_LOG_DIR:-}" ]   && sed -i "s|^dataLogDir=.*$|dataLogDir=$ZOOKEEPER_LOG_DIR|" "$config"
        [ "${ZOOKEEPER_TICK_TIME:-}" ] && sed -i "s|^tickTime=.*$|tickTime=$ZOOKEEPER_TICK_TIME|" "$config"
    fi

    printf '\n\nCurrent config: %s\n' "$config"
    cd "$KAFKA_USER_DIR"
    while read ln; do
        printf '    %s\n' "$ln"
    done < <(cat "$config")

    echo
    echo
fi