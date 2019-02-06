FROM fedora:29 AS salt-base
# "" == latest
ARG salt_ver=""

COPY salt /srv/salt
COPY reactor /srv/reactor

RUN dnf -y update && dnf -y install curl procps && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh -X -n stable $salt_ver

ENTRYPOINT [ "/usr/bin/supervisord" ]


FROM salt-base AS salt-minion

COPY .travis/config/supervisord_minion.conf /etc/supervisor/conf.d/supervisord.conf


FROM salt-base AS salt-master

COPY .travis/config/supervisord_master.conf /etc/supervisor/conf.d/supervisord.conf
COPY .travis/entrypoint_master_run.sh /opt/

RUN dnf -y install python-pip git @development-tools redhat-rpm-config python2-devel libgit2-devel && \
    pip install --upgrade pyOpenSSL pygit2 docker-py cherrypy jinja2 PyYAML requests_oauthlib google-auth && \
    dnf -y install salt-master && \
    salt-run saltutil.sync_all
# the salt-master should be installed but not running
EXPOSE 4505:4505 4506:4506


FROM salt-base AS dry-test

COPY .travis/entrypoint_dry_systemd.sh /opt/
COPY .travis/pillar/ /srv/pillar/
COPY .travis/salt/top.sls /srv/salt/base/
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf
COPY .travis/envoy_test.py /opt/

ENTRYPOINT ["/opt/entrypoint_dry_systemd.sh"]
