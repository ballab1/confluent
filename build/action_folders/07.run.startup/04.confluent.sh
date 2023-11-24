#!/bin/bash

#----------------------------------------------------------------------------------------------
function kaf_match()
{
    echo "${1,,}"
}

function zoo_match()
{
    local in="${1,,}"

    local keyWord
    for keyWord in "${zookeeper_keywords[@]}"; do
        if [ "${keyWord,,}" = "$in" ] || [ "${keyWord,,}" = "${in//./}" ]; then
            echo "$keyWord"
            return 0
        fi
    done
    echo "$in"
    return 0
}
#----------------------------------------------------------------------------------------------
function my.updateConfigFromENV()
{
    local -r env_prefix="${1:?"Input parameter 'env_prefix' must be passed to 'function ${FUNCNAME[0]}()'"}"
    local -r config_file="${2:?"Input parameter 'config_file' must be passed to 'function ${FUNCNAME[0]}()'"}"
    local -r fn="${3:?"Input parameter 'fn' must be passed to 'function ${FUNCNAME[0]}()'"}"

    [ -f "$config_file" ] || trap.die 'Property file does not exist'

    local key
    for key in $(env | grep -E "^$env_prefix"); do
        key="${key#$env_prefix}"
        local val=${key##*=}
        key="${key%%=*}"
        key=$($fn "${key//_/.}")
        lib.updatePropertyFile "$key" "$val" "$config_file" 'must_exist'
    done
}
#----------------------------------------------------------------------------------------------

declare -a zookeeper_keywords=( 'autopurge.purgeInterval'     'autopurge.snapRetainCount'   'clientPort'
                                'clientPortAddress'           'cnxTimeout'                  'dataDir'
                                'dataLogDir'                  'electionAlg'                 'forceSync'
                                'globalOutstandingLimit'      'initLimit'                   'leaderServes'
                                'maxClientCnxns'              'maxSessionTimeout'           'minSessionTimeout'
                                'preAllocSize'                'quorumListenOnAllIPs'        'skipACL'
                                'snapCount'                   'syncEnabled'                 'syncLimit'
                                'tickTime'                    'traceFile' )


: ${KAFKA_UID:?"Environment variable 'KAFKA_UID' not defined in '${BASH_SOURCE[0]}'"}
[ "${KAFKA_BROKER_ID:-0}" -eq 0 ] && [ "${ZOOKEEPER_SERVER_ID:-0}" -eq 0 ] && trap.die 'invalid configuration: need either KAFKA_BROKER_ID or ZOOKEEPER_SERVER_ID defined'
[ "${KAFKA_BROKER_ID:-0}" -gt 0 ] && [ "${ZOOKEEPER_SERVER_ID:-0}" -gt 0 ] && trap.die "invalid configuration: cannot have both KAFKA_BROKER_ID: $KAFKA_BROKER_ID and ZOOKEEPER_SERVER_ID: $ZOOKEEPER_SERVER_ID defined"


chmod -R a+rx "$KAFKA_USER_DIR/bin"

if [ "${KAFKA_BROKER_ID:-0}" -gt 0 ]; then
    crf.fixupDirectory "$KAFKA_USER_DIR" "$KAFKA_UID"
    crf.fixupDirectory "$KAFKA_LOG_DIRS" "$KAFKA_UID"
    crf.fixupDirectory "$KAFKA_CONF_DIR" "$KAFKA_UID"

    # Generate the config only if it doesn't exist
    declare config="$KAFKA_CONF_DIR/server.properties"
    if [ -f "$config" ]; then
        my.updateConfigFromENV 'KAFKA_' "$config" 'kaf_match'
        [ "${ZOOKEEPER_TIMEOUT:-}" ] && sed -i "s|^zookeeper.connection.timeout.ms=.*$|zookeeper.connection.timeout.ms=$ZOOKEEPER_TIMEOUT|" "$config"
    fi

    printf '\n\nCurrent config: %s\n' "$config"
    cd "$KAFKA_USER_DIR" ||:
    while read -r ln; do
        printf '    %s\n' "$ln"
    done < <(cat "$config")

    echo
    echo
fi


if [ "${ZOOKEEPER_SERVER_ID:-0}" -gt 0 ]; then
    crf.fixupDirectory "$ZOOKEEPER_DATADIR" "$KAFKA_UID"
    crf.fixupDirectory "$ZOOKEEPER_DATALOGDIR" "$KAFKA_UID"
    crf.fixupDirectory "$ZOOKEEPER_CONFDIR" "$KAFKA_UID"

    # Write myid only if it doesn't exist
    echo "$ZOOKEEPER_SERVER_ID" > "$ZOOKEEPER_DATADIR/myid"
    unset ZOOKEEPER_SERVER_ID

    # Generate the config only if it doesn't exist
    config="${ZOOKEEPER_CONFDIR}/zookeeper.properties"
    [ -f "$config" ] && my.updateConfigFromENV 'ZOOKEEPER_' "$config" 'zoo_match'

    printf '\n\nCurrent config: %s\n' "$config"
    cd "$KAFKA_USER_DIR" ||:
    while read -r ln; do
        printf '    %s\n' "$ln"
    done < <(cat "$config")

    echo
    echo
fi