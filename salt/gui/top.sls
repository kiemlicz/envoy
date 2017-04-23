gui:
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

  'gpus:vendor:nvidia':
    - match: grain
    - nvidia

  'not G@os:Windows':
    - match: compound
    - sensors
    - lxc
    - users
