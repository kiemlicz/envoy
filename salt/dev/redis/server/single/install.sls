{% from "redis/server/single/map.jinja" import redis with context %}


redis:
  pkg.latest:
    - name: {{ redis.pkg_name }}
    - require:
      - pkg: os_packages
  file_ext.managed:
    - name: {{ redis.init_location }}
    - source: {{ redis.init }}
    - mode: {{ redis.mode }}
    - template: jinja
    - context:
      redis: {{ redis }}
    - require:
      - pkg: {{ redis.pkg_name }}
