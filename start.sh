#!/bin/bash

echo "Running start.sh"

SETUP_SCRIPTS=/first-run.d

for script in $SETUP_SCRIPTS/*.sh
do
	$script
done

/usr/local/bin/jenkins.sh
