pkgs:
  dist_upgrade: True
  os_packages:
    - zsh
  pip_packages:
    - pip_package
  post_install:
    - some command
    - to be executed
  scripts:
    - source: http://example.com/somescript.sh
      args: "-a -b -c"
