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
  cmd.wait:
    - names: {{ pkgs.post_install if pkgs.post_install is defined else [] }}
    - watch:
      - pkg: packages
