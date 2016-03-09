FROM openfrontier/jenkins
MAINTAINER zsx <thinkernel@gmail.com>

COPY config.xml.template start.sh jenkins-setup.sh /

USER root

RUN chown jenkins:jenkins /config.xml.template

USER jenkins

ENV LDAP_SERVER openldap

ENV JENKINS_WEBURL /jenkins

ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/jenkins.sh"]

CMD ["/start.sh"]
