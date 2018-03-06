{% from "keepalived/map.jinja" import keepalived with context %}


include:
  - pkgs

#disable arp

keepalived:
  pkg.latest:
    - name: {{ keepalived.pkg_name }}
    - require:
      - pkg: os_packages

keepalived_root_config:
  file.directory:
    - name {{ keepalived.config.include }}
    -
  file_ext.managed:
    - name: {{ keepalived.location }}
    - source: {{ keepalived.config }}
    - template: jinja
    - context:
      keepalived: {{ keepalived }}
    - require:
      - pkg: {{ keepalived.pkg_name }}

keepalived_instances_config:
  file_ext.managed:
    - name: {{ keepalived.location }}
    - source: {{ keepalived.config }}
    - template: jinja
    - context:
      keepalived: {{ keepalived }}
    - require:
      - file_ext: {{ keepalived.location }}
