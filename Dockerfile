FROM centos:centos7

USER root
WORKDIR /app

# RUN echo node1 > /etc/hostname
# RUN echo 127.0.0.1 node1 >> /etc/hosts
RUN echo "change-hostname node1"; \
    sleep 1
    # printf '%s\n' "$(hostname)" > /etc/hostname; \
    # printf '%s\t%s\t%s\n' "$(perl -C -0pe 's/([\s\S]*)\t.*$/$1/m' /etc/hosts)" "$(hostname)" > /etc/hosts; \
    # echo 'Installing more stuff...'

VOLUME /root/data
VOLUME /var/log

# prepare centos repo
RUN rm -r -f /etc/yum.repos.d/*
COPY conf/centos/Centos-7-*.repo /etc/yum.repos.d/

# yum install
RUN yum clean all
RUN yum makecache
RUN yum install -y openssh \
  openssh-server \
  openssh-clients \
  which \
  perl \
  net-tools \
  ibaio.x86_64 \
  libaio-devel.x86_64 \
  libnuma*

# ssh without key
RUN ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ''
RUN cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
RUN test -f /etc/ssh/ssh_host_ecdsa_key || /usr/bin/ssh-keygen -q -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -C '' -N ''
RUN test -f /etc/ssh/ssh_host_rsa_key || /usr/bin/ssh-keygen -q -t rsa -f /etc/ssh/ssh_host_rsa_key -C '' -N ''
RUN test -f /etc/ssh/ssh_host_ed25519_key || /usr/bin/ssh-keygen -q -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -C '' -N ''
RUN test -f /root/.ssh/authorized_keys || /usr/bin/cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
# RUN ssh -o "StrictHostKeyChecking no" root@node1

# mysql
COPY lib/mysql-community-*.rpm /app/
RUN rpm -ivh /app/mysql-community-common*.rpm
RUN rpm -ivh /app/mysql-community-libs*.rpm
RUN rpm -ivh /app/mysql-community-client*.rpm
RUN rpm -ivh /app/mysql-community-server*.rpm
COPY conf/mysql/my.cnf /etc/my.cnf

# jdk
COPY lib/openjdk-8u41-b04-linux-x64-14_jan_2020.tar.gz /app
RUN mkdir -p /app/jdk
RUN tar zxvf /app/openjdk-8u41-b04-linux-x64-14_jan_2020.tar.gz -C /app/jdk/ --strip-components 1
ENV JAVA_HOME=/app/jdk
ENV PATH=$PATH:$JAVA_HOME/bin

# zookeeper
COPY lib/apache-zookeeper-3.6.2-bin.tar.gz /app
RUN mkdir -p /app/zookeeper
RUN tar zxvf /app/apache-zookeeper-3.6.2-bin.tar.gz -C /app/zookeeper/ --strip-components 1
ENV ZK_HOME=/app/zookeeper
ENV ZOO_LOG_DIR=/var/log/zookeeper
COPY conf/zookeeper/* $ZK_HOME/conf/
ENV PATH=$PATH:$ZK_HOME/bin

# hadoop
COPY lib/hadoop-2.10.1.tar.gz /app
RUN mkdir -p /app/hadoop
RUN tar zxvf /app/hadoop-2.10.1.tar.gz -C /app/hadoop/ --strip-components 1
ENV HADOOP_HOME=/app/hadoop
ENV YARN_LOG_DIR=/var/log/hadoop
COPY conf/hadoop/* $HADOOP_HOME/etc/hadoop/
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

# spark
COPY lib/spark-2.4.7-bin-without-hadoop.tgz /app
RUN mkdir -p /app/spark
RUN tar zxvf /app/spark-2.4.7-bin-without-hadoop.tgz -C /app/spark/ --strip-components 1
ENV SPARK_HOME=/app/spark
COPY conf/spark/* $SPARK_HOME/conf/
ENV PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin

# clear files
RUN rm -r -f /app/*.gz
RUN rm -r -f /app/*.tgz
RUN rm -r -f /app/*.rpm


ADD start.sh /root/start.sh
RUN chmod -R 777 /root/start.sh
ENTRYPOINT ["/root/start.sh"]