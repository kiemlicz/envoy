{% from "pkgs/map.jinja" import pkgs with context %}

include:
  - repositories

pkgs:
  pkg.latest:
    - pkgs: {{ pkgs.names }}
    - refresh: True
    - require:
      - sls: repositories
