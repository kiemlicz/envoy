FROM ubuntu:xenial

# "" == latest
ARG SALT_VER=""

COPY salt /srv/salt
COPY .travis/pillar /srv/pillar
COPY .travis/salt/top.sls /srv/salt/base/
COPY .travis/envoy_test.py /opt/
COPY .travis/entrypoint_dry.sh /opt/
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf

RUN apt-get update && apt-get install -y curl iproute2 && \
    ln -s /srv/envoy/salt /srv/salt && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh -X -n stable $SALT_VER

ENTRYPOINT ["/opt/entrypoint_dry.sh"]
