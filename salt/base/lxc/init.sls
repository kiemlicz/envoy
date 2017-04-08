{% from "lxc/map.jinja" import lxc with context %}

include:
  - mounts
  - hosts
  - pkgs

lxc:
  pkg.latest:
    - pkgs: {{ lxc.pkgs }}
    - refresh: True
    - require:
      - sls: mounts
      - sls: hosts
      - sls: pkgs
  file.managed:
    - name: {{ lxc.net_cfg_file }}
    - source: salt://lxc/lxc-net
    - makedirs: True

#todo libvirt?
#todo add unpriviledged