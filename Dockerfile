FROM dockerfile/java:oracle-java8
MAINTAINER rocklass

# Set environment
ENV SONARQUBE_VERSION 5.0.1
ENV SONAR_JDBC_USERNAME sonar
ENV SONAR_JDBC_PASSWORD sonar
ENV SONAR_JDBC_URL jdbc:mysql://localhost:3306/sonar?useUnicode=true&characterEncoding=utf8&rewriteBatchedStatements=true
ENV CREATE_DATABASE_SCRIPT create_database.sql
ENV SUPERVISOR_CONF supervisord.conf

# Forbid daemon to start
RUN echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d 
RUN chmod +x /usr/sbin/policy-rc.d

# Install dependencies
RUN apt-get update
RUN apt-get install -y unzip mysql-server supervisor

# Install SonarQube
RUN curl -sLo sonarqube-${SONARQUBE_VERSION}.zip http://dist.sonar.codehaus.org/sonarqube-${SONARQUBE_VERSION}.zip && \
	unzip sonarqube-${SONARQUBE_VERSION}.zip -d /tmp && \
	mv /tmp/sonarqube-${SONARQUBE_VERSION} /opt/sonar && \
	rm sonarqube-${SONARQUBE_VERSION}.zip

# Update Sonar configuration
RUN sed -i 's/^#\?sonar.jdbc.username.*$/sonar.jdbc.username=\${env:SONAR_JDBC_USERNAME}/' /opt/sonar/conf/sonar.properties
RUN sed -i 's/^#\?sonar.jdbc.password.*$/sonar.jdbc.password=\${env:SONAR_JDBC_PASSWORD}/' /opt/sonar/conf/sonar.properties
RUN sed -i 's/^#\?sonar.jdbc.url.*$/sonar.jdbc.url=\${env:SONAR_JDBC_URL}/'                /opt/sonar/conf/sonar.properties

# Update MySQL configuration
RUN sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf

# Create Sonar database
ADD ${CREATE_DATABASE_SCRIPT} /tmp/${CREATE_DATABASE_SCRIPT}
RUN mysqld & sleep 10 && \
    mysql < /tmp/${CREATE_DATABASE_SCRIPT} && \
    mysqladmin shutdown

# Update supervisor configuration
RUN mkdir -p /var/log/supervisor
ADD ${SUPERVISOR_CONF} /etc/supervisor/conf.d/${SUPERVISOR_CONF}

CMD /usr/bin/supervisord -n

EXPOSE 9000 3306
