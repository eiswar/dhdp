FROM centos
MAINTAINER Eswara Moorthy <eswaramoorthy.s@tcs.com>

ADD ambari.repo /etc/yum.repos.d/ambari.repo
ADD jdk-8u144-linux-x64.tar.gz /usr/local/src/jdk-8u144-linux-x64.tar.gz
RUN mv /usr/local/src/jdk-8u144-linux-x64.tar.gz/jdk1.8.0_144 /usr/local/jdk1.8.0_144
ENV JAVA_HOME /usr/local/jdk1.8.0_144

RUN yum -y install ambari-server --nogpgcheck

COPY entrypoint.sh /usr/sbin/entrypoint.sh
RUN  chmod +x /usr/sbin/entrypoint.sh

ENTRYPOINT ["/usr/sbin/entrypoint.sh"]

