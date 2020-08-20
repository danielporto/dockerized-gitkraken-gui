# dockerized-gitkraken-gui
An example of how to embed a graphic  application into a docker container and access it via browser or vnc

This is useful to run gui applications that scan the disk and performs poorly when run over remote drives.

To run, simply clone this repository and execute docker-compose up
access gitkraken via web browser: machine:8080  (http://localhost:8080)

 the directory data is mounted into the containers.
 If you want to change it, change in the docker-compose volumes.

 To change application, review the Dockerfile.app, superfisord.conf and menu.xml and change it accordingly.
 