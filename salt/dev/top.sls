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

  'I@redis:setup_type:cluster':
    - redis.server.cluster
  'I@redis:setup_type:single':
    - redis.server.single

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
