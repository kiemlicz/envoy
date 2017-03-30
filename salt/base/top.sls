base:
  '*':
    - hosts
    - repositories
    - locale
    - pkgs
    - mounts
    - samba

  'not G@os:Windows':
    - match: compound
    - sensors
    - lxc
    - users
