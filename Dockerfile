####Dockerfile for building container using pre-compiled XNAT WAR. Based on instructions from XNAT Workshop 2016 Wiki Practical session #1 https://wiki.xnat.org/display/XW2/Part+1+Installing+XNAT
####Author: EM LoCastro
####Imaging Data Evaluation and Analysis Lab
####Weill Cornell Medical College


# Set the base image to ubuntu
FROM ubuntu:14.04

EXPOSE 8080 8104


############Prepare and condition container#########################
# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start--does this even work??
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

# Update the sources list and install base packages
RUN apt-get update && apt-get install -y tar less git curl vim wget unzip nano \
        netcat software-properties-common mercurial unzip postgresql-client nginx \
	tomcat7 tomcat7-admin tomcat7-common ca-certificates


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


####################SET UP XNAT DIRECTORIES##################
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

ADD tomcat7 /etc/default/tomcat7
RUN chown xnat:xnat /etc/default/tomcat7


############XNAT WAR###############
#download compiled 1.7 WAR  from bitbucket repository
WORKDIR ${XNAT_USER_HOME}
RUN wget https://bitbucket.org/xnatdev/xnat-web/downloads/xnat-web-1.7.0-SNAPSHOT.war
RUN wget https://bitbucket.org/xnatdev/xnat-pipeline/downloads/xnat-pipeline-1.7.0-SNAPSHOT.zip

#transfer configuration properties file
PUT xnat-conf.properties ${XNAT_USER_HOME}/config

#Copy WAR to webapps
RUN rm -rf /var/lib/tomcat7/webapps/ROOT*
RUN rsync ${XNAT_USER_HOME}/xnat-web-1.7.0-SNAPSHOT.war /var/lib/tomcat7/webapps/ROOT.war

#####################START TOMCAT
CMD service tomcat start && tail -f /var/lib/tomcat/logs/catalina.out
