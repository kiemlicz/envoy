dev:
  '*':
    - hosts
    - repositories
    - locale
    - pkgs
    - mounts
    - samba
    - keepass
    - owncloud
    - dropbox
    - spotify
    - java
    - scala
    - erlang
    - gradle
    - maven
    - sbt
    - rebar
    - intellij
    - robomongo
    - docker
    - virtualbox
    - projects
    - redis.client
    - mongodb.client

  'I@redis:setup_type:cluster and I@redis:install_type:repo':
    - match: compound
    - redis.server.cluster.repo
  'I@redis:setup_type:cluster and I@redis:install_type:docker':
    - match: compound
    - redis.server.cluster.docker
  'I@redis:setup_type:single and I@redis:install_type:repo':
    - match: compound
    - redis.server.single.repo
  'I@redis:setup_type:single and I@redis:install_type:docker':
    - match: compound
    - redis.server.single.docker

  'I@mongodb:setup_type:cluster':
    - mongodb.server.cluster
  'I@mongodb:setup_type:single and I@mongodb:install_type:repo':
    - match: compound
    - mongodb.server.single.repo
  'I@mongodb:setup_type:single and I@mongodb:install_type:docker':
    - match: compound
    - mongodb.server.single.docker

  'gpus:vendor:nvidia':
    - match: grain
    - nvidia

  'not G@os:Windows':
    - match: compound
    - lxc
    - users
