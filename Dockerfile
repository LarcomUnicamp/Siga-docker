FROM daggerok/jboss-eap-7.2:7.2.5-alpine
MAINTAINER crivano@jfrj.jus.br


#--- ADD ORACLE AND MYSQL DRIVERS
ADD --chown=jboss ./modules.tar.gz ${JBOSS_HOME}/

ARG BRANCH=master

#--- SET TIMEZONE
ENV TZ=America/Sao_Paulo
ENV LANG pt_BR.UTF-8
ENV LANGUAGE pt_BR.UTF-8
ENV LC_ALL pt_BR.UTF-8
ENV BRANCH=${BRANCH}

RUN sudo apk --update --no-cache add busybox-extras tzdata git maven
#RUN sudo yum -y install telnet

#--- SET TIMEZONE
RUN sudo sh -c "ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone"

#--- APT-GET GRAPHVIZ
RUN sudo apk add --update --no-cache graphviz ttf-freefont
#RUN sudo yum -y install graphviz

#--- CLONE FROM BRANCH
RUN echo 'Clone apartir do branch' ${BRANCH}
RUN git clone https://github.com/LarcomUnicamp/siga-doc-larcom.git -b ${BRANCH}
ADD https://api.github.com/repos/LarcomUnicamp/siga-doc-larcom/commits/${BRANCH}?per_page=1 /tmp/last_commit
RUN cd siga-doc-larcom  && git pull

#--- BUILD ARTIFACTS
RUN  cd siga-doc-larcom &&  mvn clean package -T 1C -DskipTests=true

#--- DEPLOY DO ARQUIVO .WAR FROM LOCAL BUILD
RUN cd siga-doc-larcom  && \
   mv target/siga.war ${JBOSS_HOME}/standalone/deployments/    && \
   mv target/sigaex.war ${JBOSS_HOME}/standalone/deployments/  && \
   mv target/sigawf.war ${JBOSS_HOME}/standalone/deployments/  && \
   mv target/sigasr.war ${JBOSS_HOME}/standalone/deployments/  && \
   mv target/sigagc.war ${JBOSS_HOME}/standalone/deployments/  && \
   mv target/sigatp.war ${JBOSS_HOME}/standalone/deployments/

#--- ou copie diretamente do diretÃ³rio siga-docker para fins de debug
# COPY --chown=jboss ./*.war ${JBOSS_HOME}/standalone/deployments/

#--- COPIANDO standalone.xml ---
COPY --chown=jboss ./standalone.xml ${JBOSS_HOME}/standalone/configuration/standalone.xml

#--- COPIANDO wait-for-it.sh ---
RUN mkdir  bin
COPY ./wait-for-it.sh bin/wait-for-it.sh
RUN sudo chmod +x bin/wait-for-it.sh

EXPOSE 8080