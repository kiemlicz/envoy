{% from "lxc/map.jinja" import lxc with context %}

include:
  - repositories
  - pkgs
  - mounts
  - hosts

lxc:
  pkg.latest:
    - pkgs: {{ lxc.pkgs }}
    - refresh: True
    - require:
      - sls: repositories
      - sls: pkgs
      - sls: mounts
      - sls: hosts
  file.managed:
    - name: {{ lxc.net_cfg_file }}
    - source: salt://lxc/lxc-net
    - makedirs: True

#todo libvirt?
#todo add unpriviledged