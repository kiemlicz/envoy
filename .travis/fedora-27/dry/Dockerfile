FROM fedora:27

# "" == latest
ARG SALT_VER=""

COPY salt /srv/salt
COPY extensions /srv/extensions
COPY .travis/pillar /srv/pillar
COPY .travis/envoy_test.py /opt/
COPY .travis/entrypoint_dry.sh /opt/
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf

RUN dnf -y update && dnf -y install curl && \
    ln -s /srv/envoy/salt /srv/salt && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh -X -n stable $SALT_VER

ENTRYPOINT ["/opt/entrypoint_dry.sh"]
