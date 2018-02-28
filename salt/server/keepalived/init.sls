{% from "keepalived/map.jinja" import keepalived with context %}

include:
  - pkgs

#fixme the keepalived config file requires minions upfront,
#consider orchestrator usage

keepalived:
  pkg.latest:
    - name: {{ keepalived.pkg_name }}
    - require:
      - pkg: os_packages
  file_ext.managed:
    - name: {{ keepalived.location }}
    - source: {{ keepalived.config }}
    - template: jinja
    - require:
      - pkg: {{ keepalived.pkg_name }}
