#!/bin/bash

set -e

JENKINS_SETUP=jenkins-setup.sh
if [[ -x /$JENKINS_SETUP ]]; then 
	/$JENKINS_SETUP
else 
	echo "FILE NOT FOUND!"
fi

exec java $JAVA_OPTS -jar /usr/share/jenkins/jenkins.war $JENKINS_OPTS \"\$@\"





