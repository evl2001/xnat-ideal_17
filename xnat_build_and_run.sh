#!/bin/bash

#Run script from main parent directory xnat-ideal_17
#Build tomcat container

TSTAMP=`date +%s`

docker build -t idealctp/xnat:tomcat_${TSTAMP} ./

#Pull and start postgres container

docker pull postgres

docker run -d \
	--name xnat-postgres_${TSTAMP} \
	-e POSTGRES_USER=xnat \
	-e POSTGRES_PASSWORD=xnat \
	postgres


#Link tomcat container & run

docker run -it \
	--name xnat-stack_${TSTAMP} \
	--link xnat-postgres_${TSTAMP}:postgres \
	-P \
	idealctp/xnat:tomcat_${TSTAMP} \
	/bin/bash
