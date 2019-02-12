FROM ubuntu:bionic AS salt-base
# "" == latest
ARG salt_ver=""

COPY salt /srv/salt

RUN apt-get update && \
    apt-get remove -y gnupg iproute2 && \
    apt-get install -y --reinstall gnupg2 && \
    apt-get install -y curl dirmngr iproute2 supervisor && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh -X -n stable $salt_ver

ENTRYPOINT [ "/usr/bin/supervisord" ]


FROM salt-base AS salt-minion

COPY .travis/config/no_daemon_env /etc/default/salt-minion
COPY .travis/config/supervisord_minion.conf /etc/supervisor/conf.d/supervisord.conf


FROM salt-base AS salt-master

COPY .travis/config/no_daemon_env /etc/default/salt-master
COPY .travis/config/supervisord_master.conf /etc/supervisor/conf.d/supervisord.conf

RUN curl -L https://gist.githubusercontent.com/kiemlicz/33e891dd78e985bd080b85afa24f5d0a/raw/6e2bada50bee197ef0fe15ab615a8f07420c7dc0/init.sh | bash && \
    apt-get install -y salt-master && \
    salt-run saltutil.sync_all
# the salt-master should be installed but not running
EXPOSE 4505:4505 4506:4506


FROM salt-base AS dry-test

COPY .travis/entrypoint_dry.sh /opt/
COPY .travis/reactor /srv/reactor
COPY .travis/pillar/ /srv/pillar/
COPY .travis/salt/top.sls /srv/salt/base/
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf
COPY .travis/envoy_test.py /opt/

ENTRYPOINT ["/opt/entrypoint_dry.sh"]
