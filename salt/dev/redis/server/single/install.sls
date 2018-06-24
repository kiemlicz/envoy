{% from "redis/server/single/map.jinja" import redis with context %}


redis:
  pkg.latest:
    - name: {{ redis.pkg_name }}
    - require:
      - sls: os
  file_ext.managed:
    - name: {{ redis.config.init_location }}
    - source: {{ redis.config.init }}
    - mode: {{ redis.config.mode }}
    - template: jinja
    - context:
      redis: {{ redis|json_decode_dict }}
    - require:
      - pkg: {{ redis.pkg_name }}
