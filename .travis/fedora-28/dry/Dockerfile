FROM fedora:28

# "" == latest
ARG SALT_VER="2018.3.0"

COPY salt /srv/salt
COPY extensions /srv/extensions
COPY .travis/pillar /srv/pillar
COPY .travis/salt/top.sls /srv/salt/base/
COPY .travis/envoy_test.py /opt/
COPY .travis/entrypoint_dry_systemd.sh /opt/
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf

RUN dnf -y update && dnf -y install curl procps && \
    ln -s /srv/envoy/salt /srv/salt && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh -X -n stable $SALT_VER

ENTRYPOINT ["/opt/entrypoint_dry_systemd.sh"]
