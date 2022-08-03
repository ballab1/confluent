ARG FROM_BASE=${DOCKER_REGISTRY:-s2.ubuntu.home:5000/}${CONTAINER_OS:-alpine}/openjdk/${JAVA_VERSION:-11.0.15_p10-r0}:${BASE_TAG:-latest}
FROM $FROM_BASE

# name and version of this docker image
ARG CONTAINER_NAME=confluent
# Specify CBF version to use with our configuration and customizations
ARG CBF_VERSION

# include our project files
COPY build Dockerfile /tmp/

# set to non zero for the framework to show verbose action scripts
#    (0:default, 1:trace & do not cleanup; 2:continue after errors)
ENV DEBUG_TRACE=0


ENV KAFKA_UID=1000
ARG KAFKA_USER_NAME=kafka
ARG KAFKA_USER_DIR=/usr/local/confluent

    
# confluent version being bundled in this docker image
ARG SCALA_DISTRO=2.12
LABEL kafka.scala.distro=$SCALA_DISTRO 
ARG CONFLUENT_VERSION=7.2.0
LABEL version.confluent=$CONFLUENT_VERSION


# build content
RUN set -o verbose \
    && chmod u+rwx /tmp/build.sh \
    && /tmp/build.sh "$CONTAINER_NAME" "$DEBUG_TRACE" "$TZ" \
    && ([ "$DEBUG_TRACE" != 0 ] || rm -rf /tmp/*)


WORKDIR "$KAFKA_USER_DIR"


ENTRYPOINT [ "docker-entrypoint.sh" ]
#CMD ["$CONTAINER_NAME"]
CMD ["confluent"]
