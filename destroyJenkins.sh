#!/bin/bash

JENKINS_NAME=${JENKINS_NAME:-jenkins}
JENKINS_VOLUME=${JENKINS_VOLUME:-jenkins-volume}

echo "Removing ${JENKINS_NAME}..."
docker stop ${JENKINS_NAME} &> /dev/null
docker rm -v ${JENKINS_NAME} &> /dev/null
echo "Removing ${JENKINS_VOLUME}..."
docker rm -v ${JENKINS_VOLUME} &> /dev/null
