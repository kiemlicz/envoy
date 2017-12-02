{% from "redis/server/single/map.jinja" import redis with context %}
{% set instance = redis.name + '-' + redis.port %}

redis_config_{{ redis.host }}_{{ redis.port }}:
  file_ext.managed:
    - name: /etc/redis/{{ instance }}.conf
    - source: {{ redis.config }}
    - makedirs: True
    - template: jinja
    - context:
      bind:
        host: {{ redis.host }}
        port: {{ redis.port }}
    - require:
      - file_ext: {{ redis.init_location }}
  service.running:
    - name: {{ redis.service }}@{{ instance }}
    - enable: True
    - require:
      - file_ext: /etc/redis/{{ instance }}.conf
