{% from "pkgs/map.jinja" import pkgs with context %}

include:
  - repositories

pkgs:
  pkg.latest:
    - pkgs: {{ pkgs.names }}
    - refresh: True
    - require:
      - sls: repositories
{% if pkgs.post_install is defined %}
  cmd.wait:
    - names: {{ pkgs.post_install }}
    - watch:
      - pkg: {{ pkgs.names }}
{% endif %}
