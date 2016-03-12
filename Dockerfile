FROM jenkins
MAINTAINER shiv <shiv@demo.com>

ENV LDAP_SERVER openldap

ENV JENKINS_WEBURL http://127.0.0.1/jenkins

# Install plugins
COPY plugins.txt /usr/local/etc/plugins.txt
RUN /usr/local/bin/plugins.sh /usr/local/etc/plugins.txt

# Add gerrit-trigger, credentials, maven plugin config files and initial email/URL config
# to /usr/share/jenkins/ref so that base docker image script will copy them to JENKINS_HOME
COPY config.xml.override \
    gerrit-trigger.xml \
    credentials.xml \
    hudson.tasks.Maven.xml \
    jenkins.model.JenkinsLocationConfiguration.xml \
    usr/share/jenkins/ref/


COPY start.sh /


USER root

RUN mkdir -p /first-run.d/

COPY jenkins-setup.sh /first-run.d/

RUN chown -R jenkins:jenkins /usr/share/jenkins/ref/
RUN chown -R jenkins:jenkins /first-run.d/
RUN chown jenkins:jenkins /start.sh

USER jenkins
ENTRYPOINT ["/bin/tini", "/start.sh"]
