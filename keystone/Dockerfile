FROM ubuntu:14.04
MAINTAINER hafe

RUN apt-get update && apt-get install -y \
    git \
    python-pip \
    python-dev python3-dev libxml2-dev libxslt1-dev \
        libsasl2-dev libsqlite3-dev libssl-dev libldap2-dev libffi-dev && \
    rm -f /var/lib/keystone/keystone.sqlite

# upgrade pip
RUN pip install --upgrade pip

# https://github.com/paulczar/openstack-on-docker/blob/master/keystone/Dockerfile

ENV VERSION=stable/mitaka
#ENV VERSION=master

RUN \
  git clone --depth 1 -b $VERSION https://github.com/openstack/keystone.git /app/keystone && \
  cd /app/keystone && \
  pip install -r /app/keystone/requirements.txt && \
  python setup.py install && \
  mkdir -p /etc/keystone && \
  chmod 0700 /etc/keystone

RUN \
  cd /app/keystone/etc && \
    cp default_catalog.templates /etc/keystone && \
    cp keystone.conf.sample /etc/keystone/keystone.conf && \
    cp keystone-paste.ini /etc/keystone && \
    cp logging.conf.sample /etc/keystone/logging.conf && \
    cp policy.json /etc/keystone

RUN pip install python-memcached>=1.56 python-ldap ldappool

RUN pip install python-openstackclient

RUN apt-get install -y \
    crudini \
    mysql-client \
    python-mysqldb

# Static configuration of keystone (dynamic in start script)
RUN crudini --set /etc/keystone/keystone.conf token provider keystone.token.providers.uuid.Provider && \
    crudini --set /etc/keystone/keystone.conf token driver keystone.token.persistence.backends.sql.Token && \
    crudini --set /etc/keystone/keystone.conf revoke driver keystone.contrib.revoke.backends.sql.Revoke && \
    crudini --set /etc/keystone/keystone.conf cache enabled true && \
    crudini --set /etc/keystone/keystone.conf cache backend dogpile.cache.memcached && \
    rm -f /var/lib/keystone/keystone.db

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

EXPOSE 5000 35357

COPY start.sh /
COPY start-2.sh /
COPY post-start.sh /
RUN chmod +x /start.sh && chmod +x /start-2.sh
CMD ["/start.sh"]
RUN mkdir -p /etc/keystone/domains
COPY keystone.acme.conf /etc/keystone/domains/

RUN mkdir -p /opt/kolla
COPY service_hosts.sh /opt/kolla/service_hosts.sh
COPY kolla-common.sh /opt/kolla/kolla-common.sh
COPY crux.sh /opt/kolla/crux.sh
COPY create-endpoints.sh /

#RUN pip uninstall oslo.messaging 
RUN pip install oslo.messaging==5.12.0

#RUN apt-get install -y apache2 libapache2-mod-wsgi
#COPY wsgi-keystone.conf /etc/apache2/sites-available/
#RUN ln -s /etc/apache2/sites-available/wsgi-keystone.conf /etc/apache2/sites-enabled
#RUN echo "ServerName 172.17.0.4" >>  /etc/apache2/apache2.conf
#RUN useradd keystone
#RUN service apache2 restart
#COPY start.sh /
#RUN chmod +x /start.sh && chmod +x /start-2.sh
#RUN update-rc.d -f apache2 start
