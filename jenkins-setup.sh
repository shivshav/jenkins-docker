#!/bin/bash

echo "FILE IS RUNNING!"

GERRIT_NAME=gerrit
GERRIT_WEBURL=$GERRIT_ENV_GERRIT_WEBURL
#NEXUS_REPO=$4

SLAPD_DOMAIN=$OPENLDAP_ENV_SLAPD_DOMAIN
LDAP_ACCOUNTBASE=$OPENLDAP_ENV_LDAP_ACCOUNTBASE
LDAP_NAME=$LDAP_SERVER
DEFAULT_CONFIG_XML=config.xml


# Replace '/' in url to '\/'
[ "${GERRIT_WEBURL%/}" = "${GERRIT_WEBURL}" ] && GERRIT_WEBURL="${GERRIT_WEBURL}/"
while [ -n "${GERRIT_WEBURL}" ]; do
GERRIT_URL="${GERRIT_URL}${GERRIT_WEBURL%%/*}\/"
GERRIT_WEBURL="${GERRIT_WEBURL#*/}"
done



#Convert FQDN to LDAP base DN
SLAPD_TMP_DN=".${SLAPD_DOMAIN}"
while [ -n "${SLAPD_TMP_DN}" ]; do
SLAPD_DN=",dc=${SLAPD_TMP_DN##*.}${SLAPD_DN}"
SLAPD_TMP_DN="${SLAPD_TMP_DN%.*}"
done
SLAPD_DN="${SLAPD_DN#,}"

LDAP_ACCOUNTBASE="$( cut -d ',' -f 1 <<< "$LDAP_ACCOUNTBASE" )"

#Create config.xml
sed -e "s/{SLAPD_DN}/${SLAPD_DN}/g" /${DEFAULT_CONFIG_XML}.template > ${JENKINS_HOME}/${DEFAULT_CONFIG_XML}
sed -i "s/{LDAP_NAME}/${LDAP_NAME}/g" ${JENKINS_HOME}/${DEFAULT_CONFIG_XML}
sed -i "s/{LDAP_ACCOUNTBASE}/${LDAP_ACCOUNTBASE}/g" ${JENKINS_HOME}/${DEFAULT_CONFIG_XML}

#create ssh key.
ssh-keygen -q -N '' -t rsa  -f /var/jenkins_home/.ssh/id_rsa

### Not sure if this is necessary!
# Creating the jenkins user in gerrit?
#docker exec jenkins cat /var/jenkins_home/.ssh/id_rsa.pub | ssh -i "~/.ssh/id_rsa" -p 29418 admin@0.0.0.0 #gerrit create-account --group "'Non-Interactive Users'" --full-name "'Jenkins Server'" --ssh-key - jenkins
#gather server rsa key
##TODO: This is not an elegant way.
#[ -f ~/.ssh/known_hosts ] && mv ~/.ssh/known_hosts ~/.ssh/known_hosts.bak
#ssh-keyscan -p 29418 -t rsa ${GERRIT_SSH_HOST} > ~/.ssh/known_hosts


# Setup gerrit-trigger.xml
cp /usr/local/etc/gerrit-trigger.xml ${JENKINS_HOME}/gerrit-trigger.xml
sed -i "s/{GERRIT_NAME}/${GERRIT_NAME}/g" ${JENKINS_HOME}/gerrit-trigger.xml
sed -i "s/{GERRIT_URL}/${GERRIT_URL}/g" ${JENKINS_HOME}/gerrit-trigger.xml

# Setup credentials.xml
cp /usr/local/etc/credentials.xml ${JENKINS_HOME}/credentials.xml

# Setup maven installation
cp /usr/local/etc/hudson.tasks.Maven.xml ${JENKINS_HOME}/hudson.tasks.Maven.xml

# Replace '/' in url to '\/'
[ "${JENKINS_WEBURL%/}" = "${JENKINS_WEBURL}" ] && JENKINS_WEBURL="${JENKINS_WEBURL}/"
while [ -n "${JENKINS_WEBURL}" ]; do
JENKINS_URL="${JENKINS_URL}${JENKINS_WEBURL%%/*}\/"
JENKINS_WEBURL="${JENKINS_WEBURL#*/}"
done

# Setup Jenkins url and system admin e-mail
cp /usr/local/etc/jenkins.model.JenkinsLocationConfiguration.xml \
  ${JENKINS_HOME}/jenkins.model.JenkinsLocationConfiguration.xml
sed -i "s/{JENKINS_URL}/${JENKINS_URL}/g" \
  ${JENKINS_HOME}/jenkins.model.JenkinsLocationConfiguration.xml

# Setup Jenkins Docker
#chown -R jenkins:jenkins /usr/local/etc/config.xml
#cp /usr/local/etc/config.xml ${JENKINS_HOME}/config.xml
