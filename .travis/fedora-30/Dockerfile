FROM fedora:30 AS salt-base
# "" == latest
ARG salt_ver=""

COPY salt /srv/salt

RUN dnf -y update && dnf -y install curl procps && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh -x python3 -X -n stable $salt_ver && \
    alternatives --install /usr/bin/python python /usr/bin/python2.7 10 && \
    alternatives --install /usr/bin/python python /usr/bin/python3.7 20

ENTRYPOINT [ "/usr/bin/supervisord" ]


FROM salt-base AS salt-minion

COPY .travis/config/no_daemon_env /etc/default/salt-minion
COPY .travis/config/supervisord_minion.conf /etc/supervisor/conf.d/supervisord.conf


FROM salt-base AS salt-master

COPY .travis/config/no_daemon_env /etc/default/salt-master
COPY .travis/config/supervisord_master.conf /etc/supervisor/conf.d/supervisord.conf

RUN dnf -y install python3-pip git @development-tools redhat-rpm-config python3-devel libgit2-devel && \
    alternatives --install /usr/bin/pip pip /usr/bin/pip3 20 && \
    pip3 install --upgrade pyOpenSSL pygit2 docker-py cherrypy jinja2 PyYAML requests_oauthlib google-auth && \
    dnf -y install salt-master

# somehow installed pip3 as pip alternative didn't work
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
