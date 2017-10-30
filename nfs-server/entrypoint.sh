#!/bin/bash

# Make sure we react to these signals by running stop() when we see them - for clean shutdown
# And then exiting
trap "stop; exit 0;" SIGTERM SIGINT

stop()
{
  # We're here because we've seen SIGTERM, likely via a Docker stop command or similar
  # Let's shutdown cleanly
  echo "SIGTERM caught, terminating NFS process(es)..."
  /usr/sbin/exportfs -ua
  pid1=$(ps -C rpc.nfsd h | awk '{ print $1 }')
  pid2=$(ps -C rpc.mountd h | awk '{ print $1 }')
  kill -TERM $pid1 $pid2 > /dev/null 2>&1
  echo "Terminated."
  exit
}

if [ -z "$NFS_DATA_DIR" ]; then
  echo "The NFS_DATA_DIR environment variable is null, exiting..."
  exit 1
fi

MOUNT_OPTIONS="rw,fsid=0,async,no_subtree_check,no_auth_nlm,insecure,no_root_squash"

echo "${NFS_DATA_DIR} *(${MOUNT_OPTIONS})" > /etc/exports
/usr/sbin/rpcbind -w -f &
exportfs -a
echo "Starting NFS Service.."
/usr/sbin/rpc.nfsd --debug 8
echo "Starting Mountd Service.."
/usr/sbin/rpc.mountd --debug all
echo "Starting Statd Service.."
/usr/sbin/rpc.statd

# Check the mount service at regular intervals, exit the loop when NFS service goes down.

mount_pid=$(ps -C rpc.mountd h | awk '{ print $1 }')
echo "Monitoring the mount service(${mount_pid})"
while kill -0 $mount_pid 2> /dev/null; do
        sleep 1
done

exit 1
