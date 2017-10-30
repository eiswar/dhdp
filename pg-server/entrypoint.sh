#!/bin/bash

# Make sure we react to these signals by running stop() when we see them - for clean shutdown
# And then exiting
trap "stop; exit 0;" SIGTERM SIGINT

PGDATA="${NFS_DATA_DIR}/pgdata"
export PGDATA

stop()
{
	# We're here because we've seen SIGTERM, likely via a Docker stop command or similar
	# Let's shutdown cleanly
	echo "SIGTERM caught, terminating postgresql process(es)..."
	su - postgres -c "pg_ctl -D ${PGDATA} -l logfile stop"
	rm -fv ${PGDATA}/postmaster.pid
	echo "Terminated."
	exit
}

if [ -z "${NFS_DATA_DIR}" ] || [ -z "${NFS_HOST}" ]
then
        echo "NFS data directory or NFS server IP address is not set."
        echo "Please set NFS_DATA_DIR and NFS_HOST and restart the container.."
        echo "Exiting.."
        exit 1
fi

mkdir -p ${NFS_DATA_DIR}
mount -o nolock ${NFS_HOST}:${NFS_DATA_DIR} ${NFS_DATA_DIR}
if [ $? -ne 0 ]
then
	echo "Could not mount the NFS storage"
	echo "Exiting.."
	exit 1
fi

if [ ! "$(ls -A $PGDATA)" ]; 
then
        echo "Initializing the database..."
	mkdir ${PGDATA}
	chown postgres. ${PGDATA}
        su - postgres -c "initdb -D ${PGDATA}"
        if [ -z "${PGPASSWORD}" ] || [ -z "${PGHOSTS}" ]
        then
                echo "Postgresql password or Postgresql client IP address range is not set"
                echo "Please set PGPASSWORD and PGHOSTS correctly"
                echo "Exiting.."
                exit 1
        else
                su - postgres -c "pg_ctl -D ${PGDATA} -l logfile start"
                sleep 3
                psql -U postgres -c "ALTER USER postgres WITH PASSWORD '${PGPASSWORD}'"
                su - postgres -c "pg_ctl -D ${PGDATA} -l logfile stop"
                sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" ${PGDATA}/postgresql.conf
                sed -i "s|host.*all.*all.*127.0.0.1/32.*trust|host all all ${PGHOSTS} md5|g" ${PGDATA}/pg_hba.conf
        fi
fi

# Start the postgresql service
su - postgres -c "pg_ctl -D ${PGDATA} -l logfile start"

if [[ "${DEBUG}" == "true" ]] 
then
	# Interactive shell
	/bin/bash
else
        # Check the postgresql service at regular intervals, exit the loop when postgresql service goes down.

        pg_pid=$(ps -U postgres h | head -1 | awk '{ print $1 }')
        echo "Monitoring the postgresql service(${pg_pid})"
        while kill -0 $pg_pid 2> /dev/null; do
        	sleep 1
        done
fi
