FROM ubuntu:bionic AS salt-base
# "" == latest
ARG salt_ver=""

COPY salt /srv/salt

RUN apt-get update && \
    apt-get install -y curl dirmngr iproute2 supervisor && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh -x python3 -X -n stable $salt_ver

ENTRYPOINT [ "/usr/bin/supervisord" ]


FROM salt-base AS salt-minion

COPY .travis/config/no_daemon_env /etc/default/salt-minion
COPY .travis/config/supervisord_minion.conf /etc/supervisor/conf.d/supervisord.conf


FROM salt-base AS salt-master

COPY .travis/config/no_daemon_env /etc/default/salt-master
COPY .travis/config/supervisord_master.conf /etc/supervisor/conf.d/supervisord.conf

RUN apt-get install -y python3-pip && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 20 && \
    curl -L https://gist.githubusercontent.com/kiemlicz/33e891dd78e985bd080b85afa24f5d0a/raw/23b79f9a26fe9200102c5de3207a0801751ec2fe/init.sh | bash && \
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
