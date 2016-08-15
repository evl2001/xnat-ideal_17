#!/bin/bash

#Run script from main parent directory xnat-ideal_17
#Build tomcat container

docker build -t idealctp/xnat:tomcat ./

#Pull and start postgres container

docker pull postgres

docker run -d \
	--name xnat-postgres \
	-e POSTGRES_USER=xnat \
	-e POSTGRES_PASSWORD=xnat \
	postgres


#Link tomcat container & run

docker run -d \
	--name xnat-stack \
	--link xnat-postgres:postgres \
	-p 8080:8080 \
	-p 8104:8104 \
	idealctp/xnat:tomcat
