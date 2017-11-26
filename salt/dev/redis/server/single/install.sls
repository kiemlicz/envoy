{% from "redis/server/single/map.jinja" import redis with context %}

redis_pkg:
  pkg.latest:
    - name: {{ redis.pkg_name }}
    - refresh: True
    - require:
      - pkg: os_packages
# for systemd uses %i variable that allows multiple instances per node
  file_ext.managed:
    - name: {{ redis.init_location }}
    - source: {{ redis.init }}
    - require:
      - pkg: {{ redis.pkg_name }}
