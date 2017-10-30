#!/bin/bash

# Make sure we react to these signals by running stop() when we see them - for clean shutdown
# And then exiting
trap "stop; exit 0;" SIGTERM SIGINT

stop()
{
        # We're here because we've seen SIGTERM, likely via a Docker stop command or similar
        # Let's shutdown cleanly
        echo "SIGTERM caught, terminating postgresql process(es)..."
	pid=$(ps -C java h | awk '{ print $1 }')
	kill -TERM ${pid}
        echo "Terminated."
        exit
}

# Compile Ambari python scripts
python -m compileall /usr/lib/python2.6/site-packages/ambari_server/*.py
python -m compileall /usr/sbin/ambari*.py

# Extract the ambari webcontent files
mkdir -p /var/lib/ambari-server/resources/views/work/ADMIN_VIEW{2.5.2.0}
cd /var/lib/ambari-server/resources/views/work/ADMIN_VIEW{2.5.2.0} &&
	${JAVA_HOME}/bin/jar -xvf /var/lib/ambari-server/resources/views/ambari-admin-2.5.2.0.298.jar

# Configure ambari DB password
echo "${PGUSERPASS}" > /etc/ambari-server/conf/password.dat

# Configure ambari properties file
sed -i 's|$ROOT||g' /etc/ambari-server/conf/ambari.properties

echo "
java.home=/usr/local/jdk1.8.0_144
server.jdbc.connection-pool=internal
server.jdbc.database=postgres
server.jdbc.database_name=${PGDB}
server.jdbc.driver=org.postgresql.Driver
server.jdbc.hostname=${PGHOST}
server.jdbc.port=5432
server.jdbc.postgres.schema=${PGDB}
server.jdbc.rca.driver=org.postgresql.Driver
server.jdbc.rca.url=jdbc:postgresql://${PGHOST}:5432/ambari
server.jdbc.rca.user.name=${PGUSER}
server.jdbc.rca.user.passwd=/etc/ambari-server/conf/password.dat
server.jdbc.url=jdbc:postgresql://${PGHOST}:5432/${PGDB}
server.jdbc.user.name=${PGUSER}
server.jdbc.user.passwd=/etc/ambari-server/conf/password.dat
server.os_family=redhat7
server.os_type=centos7
server.persistence.type=remote
" >> /etc/ambari-server/conf/ambari.properties

# Check whether postgresql database is up or not.
# If postgresql database is not up, wait for it..

PGPASSWORD="${PGADMINPASS}"
export PGPASSWORD
until psql -h "${PGHOST}" -U "${PGADMINUSER}" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

# Check whether database exists or not..
# If the database does not exist, create a new database
PGPASSWORD="${PGADMINPASS}"
export PGPASSWORD
psql -U ${PGADMINUSER} -h ${PGHOST} -c "\l" | grep ${PGDB}
if [ $? -ne 0 ]
then

echo "
CREATE DATABASE ${PGDB};
CREATE USER ambari WITH ENCRYPTED PASSWORD '${PGUSERPASS}';
CREATE SCHEMA ${PGDB} AUTHORIZATION ambari;
ALTER SCHEMA ${PGDB} OWNER TO ${PGUSER};
ALTER ROLE ${PGUSER} SET search_path to '${PGDB}','public';
" > /tmp/ambari-db.sql

psql -U ${PGADMINUSER} -h ${PGHOST} -f /tmp/ambari-db.sql

PGPASSWORD="${PGUSERPASS}"
export PGPASSWORD
psql -U ${PGUSER} -h ${PGHOST} -f /var/lib/ambari-server/resources/Ambari-DDL-Postgres-CREATE.sql

fi

touch /var/log/ambari-server/ambari-server.log

# Run the ambari server
${JAVA_HOME}/bin/java -server -XX:NewRatio=3 -XX:+UseConcMarkSweepGC -XX:-UseGCOverheadLimit -XX:CMSInitiatingOccupancyFraction=60 -XX:+CMSClassUnloadingEnabled -Dsun.zip.disableMemoryMapping=true -Xms512m -Xmx2048m -XX:MaxPermSize=128m -Djava.security.auth.login.config=/etc/ambari-server/conf/krb5JAASLogin.conf -Djava.security.krb5.conf=/etc/krb5.conf -Djavax.security.auth.useSubjectCredsOnly=false -cp /etc/ambari-server/conf:/usr/lib/ambari-server/*:/usr/share/java/postgresql-jdbc.jar org.apache.ambari.server.controller.AmbariServer &

if [[ "${DEBUG}" == "true" ]]
then
        # Interactive shell
        /bin/bash
else
	tail -f /var/log/ambari-server/ambari-server.log 2>/dev/null
fi

