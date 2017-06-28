{% from "pkgs/map.jinja" import pkgs with context %}

include:
  - repositories

pkgs:
  pkg.latest:
    - name: packages
    - pkgs: {{ pkgs.names }}
    - refresh: True
    - require:
      - sls: repositories
{% if pkgs.post_install is defined %}
  cmd.wait:
    - names: {{ pkgs.post_install }}
    - watch:
      - pkg: packages
{% endif %}
