FROM debian:stretch AS salt-base
# "" == latest
ARG salt_ver=""

COPY salt /srv/salt
COPY reactor /srv/reactor

RUN apt-get update && apt-get install -y curl supervisor && \
    curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com && \
    sh /tmp/bootstrap-salt.sh -X -n stable $salt_ver


FROM salt-base AS salt-minion

COPY .travis/config/no_daemon_env /etc/default/salt-minion
COPY .travis/config/supervisord_minion.conf /etc/supervisor/conf.d/supervisord.conf
COPY .travis/entrypoint_minion_run.sh /opt/

ENTRYPOINT ["/opt/entrypoint_minion_run.sh"]


FROM salt-base AS salt-master

COPY .travis/config/no_daemon_env /etc/default/salt-master
COPY .travis/config/supervisord_master.conf /etc/supervisor/conf.d/supervisord.conf
COPY .travis/entrypoint_master_run.sh /opt/

#https://github.com/saltstack/salt/issues/51270
#RUN echo "deb http://ftp.debian.org/debian stretch-backports main" >> /etc/apt/sources.list.d/backports.list && \
#    apt-get update && \
#    apt-get install -t stretch-backports -y libgit2-dev && \
#    apt-get install -y python-pip libffi-dev git && \
#    pip install --upgrade pyOpenSSL pygit2 docker-py cherrypy jinja2 PyYAML requests_oauthlib google-auth && \
#    apt-get install -y salt-master
RUN curl -L https://gist.githubusercontent.com/kiemlicz/33e891dd78e985bd080b85afa24f5d0a/raw/6e2bada50bee197ef0fe15ab615a8f07420c7dc0/init.sh | bash && \
    apt-get install -y salt-master
# the salt-master should be installed but not running
EXPOSE 4505:4505 4506:4506

ENTRYPOINT [ "/opt/entrypoint_master_run.sh" ]


FROM salt-base AS dry-test

COPY .travis/entrypoint_dry.sh /opt/
COPY .travis/pillar/ /srv/pillar/
COPY .travis/salt/top.sls /srv/salt/base/
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf
COPY .travis/envoy_test.py /opt/

ENTRYPOINT ["/opt/entrypoint_dry.sh"]
