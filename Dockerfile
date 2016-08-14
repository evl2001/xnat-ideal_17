####Dockerfile for building container using pre-compiled XNAT WAR. Based on instructions from XNAT Workshop 2016 Wiki Practical session #1
# Set the base image to ubuntu
FROM ubuntu:14.04

EXPOSE 8080 8104

# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start--does this even work??
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

# Update the sources list and install base packages
RUN apt-get update && apt-get install -y tar less git curl vim wget unzip nano \
        netcat software-properties-common mercurial unzip postgresql-client nginx \
	tomcat7 tomcat7-admin tomcat7-common ca-certificates

RUN service tomcat7 stop

# Install Oracle JDK 7 via webupd8 ppa
RUN echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
        add-apt-repository ppa:webupd8team/java && \
        apt-get update && \
        apt-get install -y oracle-java7-installer

ENV JAVA_HOME /usr/lib/jvm/java-7-oracle

ENV XNAT_HOME /data/xnat
ENV XNAT_USER_HOME /data/xnat/home
ENV XNAT_USER xnat
ENV XNAT_PW xnat4life


# SET UP DIRECTORIES
RUN mkdir -p $XNAT_HOME
WORKDIR $XNAT_HOME
RUN mkdir archive  build  cache  ftp prearchive home
WORKDIR $XNAT_USER_HOME
RUN mkdir config  logs  plugins  work

#CREATE XNAT USER
RUN useradd -d ${XNAT_USER_HOME} -s /bin/bash -m xnat -p ${XNAT_PW}
RUN gpasswd -a xnat sudo


#############TOMCAT#####################
#CONFIGURE TOMCAT and HOME FOLDER PERMISSIONS
RUN chown -R xnat:xnat /data
RUN chown -Rh xnat:xnat /usr/share/tomcat*
RUN chown -Rh xnat:xnat /var/lib/tomcat7
RUN chown -Rh xnat:xnat /etc/tomcat7
RUN chown -Rh xnat:xnat /var/log/tomcat7
RUN chown -Rh xnat:xnat /var/cache/tomcat7

#TOMCAT PROPERTIES - set tomcat7 user and JAVA_HOME
#RUN sed -i 's/TOMCAT7_USER=tomcat7/TOMCAT7_USER=xnat/g' /etc/default/tomcat7
#RUN sed -i 's/TOMCAT7_GROUP=tomcat7/TOMCAT7_GROUP=xnat/g' /etc/default/tomcat7
#RUN sed -i "s/-Xmx128m/-Xmx1g -Dxnat.home=\/data\/xnat\/home/s" /etc/default/tomcat7
#RUN echo "JAVA_HOME=${JAVA_HOME}" >> /etc/default/tomcat7
ADD tomcat7 /etc/default/tomcat7
#RUN chown xnat:xnat /etc/default


###############POSTGRES###################
#CHANGE TO POSTGRES USER
RUN service postgresql start
USER postgres
RUN createuser -d xnat
RUN psql -c "ALTER USER xnat WITH PASSWORD 'xnat'"

#CHANGE TO XNAT, create DB
USER xnat
RUN createdb

RUN sudo service postgresql restart

############XNAT WAR###############
#download compiled 1.7 WAR  from bitbucket repository
WORKDIR ${XNAT_USER_HOME}
RUN wget https://bitbucket.org/xnatdev/xnat-web/downloads/xnat-web-1.7.0-SNAPSHOT.war
RUN wget https://bitbucket.org/xnatdev/xnat-pipeline/downloads/xnat-pipeline-1.7.0-SNAPSHOT.zip

WORKDIR ${XNAT_USER_HOME}/config
RUN wget -O xnat-conf.properties http://bit.ly/1Z7lRm6

###Stop TOMCAT, copy WAR
RUN sudo service tomcat7 stop
RUN rm -rf /var/lib/tomcat7/webapps/ROOT*
RUN rsync ${XNAT_USER_HOME}/xnat-web-1.7.0-SNAPSHOT.war /var/lib/tomcat7/webapps/ROOT.war


#START TOMCAT
RUN sudo service tomcat7 start
