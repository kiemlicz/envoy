{% from "redis/server/cluster.map.jinja" import redis with context %}

{% if grains['host'] == redis.host %}

{% for port in redis.ports %}

redis_config:
  file_ext.managed:
    - name: {{ redis. }}
    - source: {{ redis. }}
    - makedirs: True
    - context:
      name: {{ redis.name }}
    - require:
      - pkg: os_packages

{% endfor %}

{% endif %}
