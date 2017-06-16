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
    - lxc
    - users
