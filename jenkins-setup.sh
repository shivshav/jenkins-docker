#!/bin/bash

CI_ADMIN_UID=$OPENLDAP_ENV_CI_ADMIN_UID
CI_ADMIN_PWD=$OPENLDAP_ENV_CI_ADMIN_PWD
GERRIT_NAME=gerrit
GERRIT_WEBURL=$GERRIT_ENV_WEBURL
#NEXUS_REPO=$4

SLAPD_DOMAIN=$OPENLDAP_ENV_SLAPD_DOMAIN
LDAP_ACCOUNTBASE=$OPENLDAP_ENV_LDAP_ACCOUNTBASE
LDAP_NAME=$LDAP_SERVER
DEFAULT_CONFIG_XML=config.xml.override
REFS_DIR=/usr/share/jenkins/ref

echo "Running first-time setup..."

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

echo "Setting up templated files..."

#Create config.xml
sed -i "s/{SLAPD_DN}/${SLAPD_DN}/g" ${REFS_DIR}/${DEFAULT_CONFIG_XML}
sed -i "s/{LDAP_NAME}/${LDAP_NAME}/g" ${REFS_DIR}/${DEFAULT_CONFIG_XML}
sed -i "s/{LDAP_ACCOUNTBASE}/${LDAP_ACCOUNTBASE}/g" ${REFS_DIR}/${DEFAULT_CONFIG_XML}


# Setup gerrit-trigger.xml
sed -i "s/{GERRIT_NAME}/${GERRIT_NAME}/g" ${REFS_DIR}/gerrit-trigger.xml
sed -i "s/{GERRIT_URL}/${GERRIT_URL}/g" ${REFS_DIR}/gerrit-trigger.xml

# Replace '/' in url to '\/'
[ "${JENKINS_WEBURL%/}" = "${JENKINS_WEBURL}" ] && JENKINS_WEBURL="${JENKINS_WEBURL}/"
while [ -n "${JENKINS_WEBURL}" ]; do
    JENKINS_URL="${JENKINS_URL}${JENKINS_WEBURL%%/*}\/"
    JENKINS_WEBURL="${JENKINS_WEBURL#*/}"
done

# Setup Jenkins url and system admin e-mail
sed -i "s/{JENKINS_URL}/${JENKINS_URL}/g" ${REFS_DIR}/jenkins.model.JenkinsLocationConfiguration.xml

if [[ -n $CI_ADMIN_UID && -n $CI_ADMIN_PWD ]]; then
    #create ssh key.
    echo "Creating jenkins user's ssh key..."
    mkdir -p /var/jenkins_home/.ssh/
    ssh-keygen -q -N '' -t rsa  -f /var/jenkins_home/.ssh/id_rsa

    ### Not sure if this is necessary!
    # Creating the jenkins user in gerrit?
    echo "Waiting for Gerrit to be ready..."
    until $(curl --output /dev/null --silent --head --fail http://${CI_ADMIN_UID}:${CI_ADMIN_PWD}@gerrit:8080/gerrit); do
        printf '.'
        sleep 5
    done
    echo "Creating jenkins user in Gerrit..."
    JENKINS_USER_POST_DATA="{
    \"name\": \"Jenkins User\",
    \"ssh_key\": \"$(cat /var/jenkins_home/.ssh/id_rsa.pub)\",
    \"http_password\": \"TestPassword\",
    \"groups\": [
      \"Non-Interactive Users\"
    ]
  }"
    echo $JENKINS_USER_POST_DATA >> $(dirname $0)/jenkins-user.json
    set -x
    curl -H Content-Type:application/json \
        -X PUT \
        --data "${JENKINS_USER_POST_DATA}" \
        --user ${CI_ADMIN_UID}:${CI_ADMIN_PWD} \
        http://gerrit:8080/gerrit/a/accounts/jenkins
    set +x
fi
echo "First-time setup complete."
rm "$0"
