# dhdp
Dockerized Hortonworks Data Platform

## Goal of this project
This project is to automate the cluster setup of Hortonworks Data Platform using docker containers.

## Work done so far

- Dockerized NFS service to provide persistent storage for the docker containers
- Dockerized PostgreSQL service and Ambari service.
- Automated the setup and installation of Ambari service

## Steps to set up Ambari server

- Checkout the code in this repo
- Download java from Oracle website; place the java tar ball inside ambari-server directory; update the java tar ball filename, java home directory configurations in the Dockerfile of ambari-server(This is not automated at the moment due to Oracle java license issues)
- Update the passwords and other variables in the docker-compose.yml file.
- The NFS service is set to store the data in /var/nfs directory. This directory needs to be created before starting the containers. The docker-compose.yml file needs to be updated to store the NFS server data in some other directories.

- Build the docker images
```
cd nfs-server; docker build . -t dhdp/nfs-server; cd ..
cd pg-server; docker build . -t dhdp/pg-server; cd ..
cd ambari-server; docker build . -t dhdp/ambari-server; cd ..
```

- Run the docker containers.
```
docker-compose up -d
```

- Check the logs of docker containers.
```
docker logs CONTAINER_NAME
```

## Testing
- Once Ambari server is setup, it can be accessed through the port 8080 of the host from the browser.
