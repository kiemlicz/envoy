server:
  '*':
    - hosts
    - repositories
    - locale
    - pkgs
    - mounts
    - samba
    - owncloud
    - java
    - scala
    - erlang
    - gradle
    - maven
    - sbt
    - rebar
    - intellij
    - robomongo
    - virtualbox
    - projects
    - redis.client
    - mongodb.client

# Artful image has hard time whereas Debian does not: https://github.com/docker/for-linux/issues/230
  'not (G@virtual_subtype:Docker and G@oscodename:artful)':
    - match: compound
    - docker
    - docker.compose

  'I@redis:setup_type:cluster':
    - match: compound
    - redis.server.cluster.repo
  'I@redis:setup_type:single':
    - match: compound
    - redis.server.single

  'I@mongodb:setup_type:cluster':
    - match: compound
    - mongodb.server.cluster
  'I@mongodb:setup_type:single':
    - match: compound
    - mongodb.server.single

  'not G@os:Windows':
    - match: compound
    - lxc
    - users
    - keepalived
    - lvs
