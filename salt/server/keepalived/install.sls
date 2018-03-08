{% from "keepalived/map.jinja" import keepalived with context %}


keepalived:
  pkg.latest:
    - name: {{ keepalived.pkg_name }}
    - require:
      - pkg: os_packages
  service.running:
    - name: {{ keepalived.service }}
    - enable: True
    - require:
      - pkg: {{ keepalived.pkg_name }}
