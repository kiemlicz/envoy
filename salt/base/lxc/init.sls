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
  sysctl.present:
    - name: net.ipv4.ip_forward
    - value: 1
    - config: {{ lxc.sysctl_config_location }}

#todo libvirt?
#todo add unpriviledged