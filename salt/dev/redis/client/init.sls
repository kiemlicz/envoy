{% from "redis/client/map.jinja" import redis_client with context as redis %}

include:
  - pkgs

redis_client:
  pkg.latest:
    - name: {{ redis.pkg_name }}
    - refresh: True
    - require:
      - pkg: os_packages
