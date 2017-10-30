FROM centos
MAINTAINER Eswara Moorthy <eswaramoorthy.s@tcs.com>
RUN yum -y install nfs-utils --nogpgcheck

COPY entrypoint.sh /usr/sbin/entrypoint.sh
RUN chmod +x /usr/sbin/entrypoint.sh

ENTRYPOINT ["/usr/sbin/entrypoint.sh"]

