FROM debian:stretch-slim AS salt-base
# "" == latest
ARG salt_ver=""

COPY salt /srv/salt

RUN apt-get update && apt-get install -y curl supervisor && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh -x python3 -X -n stable $salt_ver

ENTRYPOINT [ "/usr/bin/supervisord" ]


FROM salt-base AS salt-minion

COPY .travis/config/no_daemon_env /etc/default/salt-minion
COPY .travis/config/supervisord_minion.conf /etc/supervisor/conf.d/supervisord.conf
# hostname from `docker run -h` must be used as minion ID

FROM salt-base AS salt-master

COPY .travis/config/no_daemon_env /etc/default/salt-master
COPY .travis/config/supervisord_master.conf /etc/supervisor/conf.d/supervisord.conf

RUN echo "deb http://ftp.debian.org/debian stretch-backports main" >> /etc/apt/sources.list.d/backports.list && \
    apt-get update && \
    apt-get install -t stretch-backports -y libgit2-dev && \
    apt-get install -y python3-pip libffi-dev git && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 20 && \
    pip install --upgrade pyOpenSSL pygit2==0.27.3 docker-py cherrypy jinja2 PyYAML requests_oauthlib google-auth && \
    apt-get install -y salt-master

# the salt-master should be installed but not running
EXPOSE 4505:4505 4506:4506


FROM salt-base AS dry-test

COPY .travis/reactor /srv/reactor
COPY .travis/pillar/ /srv/pillar/
COPY .travis/salt/top.sls /srv/salt/base/
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf
COPY .travis/envoy_test.py /opt/

RUN salt-call --local saltutil.sync_all

ENTRYPOINT [ "python", "/opt/envoy_test.py" ]
