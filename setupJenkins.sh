#!/bin/bash
BASEDIR=$(readlink -f $(dirname $0))
set -e
GERRIT_ADMIN_UID=${GERRIT_ADMIN_UID:-$1}
GERRIT_ADMIN_EMAIL=${GERRIT_ADMIN_EMAIL:-$2}
SSH_KEY_PATH=${SSH_KEY_PATH:-$3}
LDAP_ACCOUNTS=${LDAP_ACCOUNTS:-$4}
CHECKOUT_DIR=./.git
JENKINS_NAME=${JENKINS_NAME:-$5}
GERRIT_NAME=${GERRIT_NAME:-$6}
GERRIT_SSH_HOST=${GERRIT_SSH_HOST:-$7}
GERRIT_WEBURL=${GERRIT_WEBURL:-$8}
JENKINS_WEBURL=${JENKINS_WEBURL:-$9}
NEXUS_REPO=${NEXUS_REPO:-$10}

LDAP_NAME=${LDAP_NAME:-$11}
LDAP_VOLUME=${LDAP_VOLUME:-$12}
SLAPD_DOMAIN=${SLAPD_DOMAIN:-$13}

DEFAULT_CONFIG_XML=config.xml

#Convert FQDN to LDAP base DN
SLAPD_TMP_DN=".${SLAPD_DOMAIN}"
while [ -n "${SLAPD_TMP_DN}" ]; do
SLAPD_DN=",dc=${SLAPD_TMP_DN##*.}${SLAPD_DN}"
SLAPD_TMP_DN="${SLAPD_TMP_DN%.*}"
done
SLAPD_DN="${SLAPD_DN#,}"

LDAP_ACCOUNTS="$( cut -d ',' -f 1 <<< "$LDAP_ACCOUNTS" )"

#Create config.xml
sed -e "s/{SLAPD_DN}/${SLAPD_DN}/g" ${BASEDIR}/${DEFAULT_CONFIG_XML}.template > ${BASEDIR}/${DEFAULT_CONFIG_XML}
sed -i "s/{LDAP_NAME}/${LDAP_NAME}/g" ${BASEDIR}/${DEFAULT_CONFIG_XML}
sed -i "s/{LDAP_ACCOUNTS}/${LDAP_ACCOUNTS}/g" ${BASEDIR}/${DEFAULT_CONFIG_XML} 


#create ssh key.
##TODO: check key existence before create one.
docker exec ${JENKINS_NAME} ssh-keygen -q -N '' -t rsa  -f /var/jenkins_home/.ssh/id_rsa

#gather server rsa key
##TODO: This is not an elegant way.
[ -f ~/.ssh/known_hosts ] && mv ~/.ssh/known_hosts ~/.ssh/known_hosts.bak
ssh-keyscan -p 29418 -t rsa ${GERRIT_SSH_HOST} > ~/.ssh/known_hosts
#create jenkins account in gerrit.
##TODO: check account existence before create one.
docker exec ${JENKINS_NAME} cat /var/jenkins_home/.ssh/id_rsa.pub | ssh -i "${SSH_KEY_PATH}" -p 29418 ${GERRIT_ADMIN_UID}@${GERRIT_SSH_HOST} gerrit create-account --group "'Non-Interactive Users'" --full-name "'Jenkins Server'" --ssh-key - jenkins

#checkout project.config from All-Project.git
[ -d ${CHECKOUT_DIR} ] && mv ${CHECKOUT_DIR}  ${CHECKOUT_DIR}.$$
mkdir ${CHECKOUT_DIR}

git init ${CHECKOUT_DIR}
cd ${CHECKOUT_DIR}

#start ssh agent and add ssh key
eval $(ssh-agent)
ssh-add "${SSH_KEY_PATH}"

#git config
git config user.name  ${GERRIT_ADMIN_UID}
git config user.email ${GERRIT_ADMIN_EMAIL}
git remote add origin ssh://${GERRIT_ADMIN_UID}@${GERRIT_SSH_HOST}:29418/All-Projects 
#checkout project.config
git fetch -q origin refs/meta/config:refs/remotes/origin/meta/config
git checkout meta/config

#add label.Verified
git config -f project.config label.Verified.function MaxWithBlock
git config -f project.config --add label.Verified.defaultValue  0
git config -f project.config --add label.Verified.value "-1 Fails"
git config -f project.config --add label.Verified.value "0 No score"
git config -f project.config --add label.Verified.value "+1 Verified"
##commit and push back
git commit -a -m "Added label - Verified"

#Change global access right
##Remove anonymous access right.
git config -f project.config --unset access.refs/*.read "group Anonymous Users"
##add Jenkins access and verify right
git config -f project.config --add access.refs/heads/*.read "group Non-Interactive Users"
git config -f project.config --add access.refs/tags/*.read "group Non-Interactive Users"
git config -f project.config --add access.refs/heads/*.label-Code-Review "-1..+1 group Non-Interactive Users"
git config -f project.config --add access.refs/heads/*.label-Verified "-1..+1 group Non-Interactive Users"
##add project owners' right to add verify flag
git config -f project.config --add access.refs/heads/*.label-Verified "-1..+1 group Project Owners"
##commit and push back
git commit -a -m "Change access right." -m "Add access right for Jenkins. Remove anonymous access right"
git push origin meta/config:meta/config

#stop ssh agent
kill ${SSH_AGENT_PID}

cd -
rm -rf ${CHECKOUT_DIR}
[ -d ${CHECKOUT_DIR}.$$ ] && mv ${CHECKOUT_DIR}.$$  ${CHECKOUT_DIR}
docker cp ${BASEDIR}/${DEFAULT_CONFIG_XML} ${JENKINS_NAME}:/usr/local/etc/${DEFAULT_CONFIG_XML}
#Setup gerrit-trigger plugin and restart jenkins
docker exec ${JENKINS_NAME} \
jenkins-setup.sh \
${GERRIT_NAME} \
${GERRIT_WEBURL} \
${JENKINS_WEBURL} \
${NEXUS_REPO}

docker restart ${JENKINS_NAME}

