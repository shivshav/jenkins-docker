#!/bin/bash
set -e
JENKINS_NAME=${JENKINS_NAME:-$1}
JENKINS_VOLUME=${JENKINS_VOLUME:-$2}
GERRIT_NAME=${GERRIT_NAME:-$3}
JENKINS_IMAGE_NAME=${JENKINS_IMAGE_NAME:-$4}
JENKINS_OPTS=${JENKINS_OPTS:-$5}
TIMEZONE=${TIMEZONE:-$6}




# Create Jenkins volume.
if [ -z "$(docker ps -a | grep ${JENKINS_VOLUME})" ]; then
    docker run \
    --name ${JENKINS_VOLUME} \
    --entrypoint="echo" \
    ${JENKINS_IMAGE_NAME} \
    "Create Jenkins volume."
fi

# Start Jenkins.
docker run \
--name ${JENKINS_NAME} \
--link ${GERRIT_NAME}:gerrit \
-p 50000:50000 \
--volumes-from ${JENKINS_VOLUME} \
-e JAVA_OPTS="-Duser.timezone=${TIMEZONE}" \
-d ${JENKINS_IMAGE_NAME} ${JENKINS_OPTS}
