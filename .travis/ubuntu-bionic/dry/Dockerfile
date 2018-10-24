FROM ubuntu:bionic

# "" == latest
ARG SALT_VER=""

COPY salt /srv/salt
COPY .travis/pillar /srv/pillar
COPY .travis/salt/top.sls /srv/salt/base/
COPY .travis/envoy_test.py /opt/
COPY .travis/entrypoint_dry.sh /opt/
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf

RUN apt-get update && apt-get remove -y gnupg iproute2 && \
    apt-get install -y --reinstall gnupg2 && \
    apt-get install -y curl dirmngr && \
    ln -s /srv/envoy/salt /srv/salt && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh -X -n -d stable $SALT_VER

ENTRYPOINT ["/opt/entrypoint_dry.sh"]
