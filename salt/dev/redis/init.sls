{% from "redis/map.jinja" import redis with context %}

include:
  - pkgs

redis:
  pkg.latest:
    - name: {{ redis.pkg_name }}
    - refresh: True
    - require:
      - sls: pkgs
