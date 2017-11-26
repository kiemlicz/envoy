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
    - mongodb
    - docker
    - projects
    - intellij
    - robomongo
    - virtualbox
  'redis:setup_type:cluster':
    - redis.server.cluster
  'redis:setup_type:single':
    - redis.server.single

  'gpus:vendor:nvidia':
    - match: grain
    - nvidia

  'not G@os:Windows':
    - match: compound
    - lxc
    - users
