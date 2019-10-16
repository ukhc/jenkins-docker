FROM jenkins/jenkins:2.199
USER root

#Installing Docker
RUN apt-get update && apt-get install software-properties-common apt-transport-https ca-certificates -y; \
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -;\
add-apt-repository  "deb [arch=amd64] https://download.docker.com/linux/debian  $(lsb_release -cs) stable";\
apt-get update && apt-get install docker-ce -y

# Create the docker daemon file
RUN mkdir -p /etc/docker
COPY /configs/docker-daemon.json /etc/docker/daemon.json

#Installing kubectl from Docker
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -;\
touch /etc/apt/sources.list.d/kubernetes.list;\
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list;\
apt-get update && apt-get install -y kubectl

#Pre-Install Jenkins Plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

# add users
COPY --chown=jenkins:jenkins /configs/users "$JENKINS_HOME"/users/

# Add the main config file to the jenkins path  
COPY --chown=jenkins:jenkins /configs/jenkins_home_config.xml "$JENKINS_HOME"/config.xml

# Disable Job DSL script security  
COPY --chown=jenkins:jenkins /configs/javaposse.jobdsl.plugin.GlobalJobDslSecurityConfiguration.xml "$JENKINS_HOME"/javaposse.jobdsl.plugin.GlobalJobDslSecurityConfiguration.xml

# Create the seed job
# Name the job
ARG job_name_1="seed_job"
# Create the job workspaces  
RUN su -c "mkdir -p "$JENKINS_HOME"/workspace/${job_name_1}/" jenkins
# Create build file structure  
RUN su -c "mkdir -p "$JENKINS_HOME"/jobs/${job_name_1}/" jenkins 
RUN su -c "mkdir -p "$JENKINS_HOME"/jobs/${job_name_1}/latest/" jenkins
RUN su -c "mkdir -p "$JENKINS_HOME"/jobs/${job_name_1}/builds/1/" jenkins
# Add the custom configs to the container  
COPY --chown=jenkins:jenkins /configs/${job_name_1}_config.xml "$JENKINS_HOME"/jobs/${job_name_1}/config.xml

# Grant jenkins user group access to /var/run/docker.sock
RUN addgroup --gid 1001 dsock
RUN gpasswd -a jenkins dsock 
USER jenkins