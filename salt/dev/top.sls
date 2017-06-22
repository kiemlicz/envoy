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
    - redis
    - intellij
    - robomongo
    - virtualbox

  'gpus:vendor:nvidia':
    - match: grain
    - nvidia

  'not G@os:Windows':
    - match: compound
    - lxc
    - users
