{% from "redis/server/single/map.jinja" import redis with context %}
{% from "redis/server/macros.jinja" import redis_configure with context %}
{% from "_common/ip.jinja" import ip with context %}
{% from "_common/util.jinja" import is_docker with context %}


{% set bind = {
  'port': redis.port,
  'ip': redis.ip|default(ip())
} %}

redis_config_{{ bind.ip }}_{{ bind.port }}:
  file_ext.managed:
    - name: /etc/redis/{{ redis.service }}.conf
    - source: {{ redis.config }}
    - makedirs: True
    - template: jinja
    - context:
      bind: {{ bind }}
      redis: {{ redis }}
      discriminator: {{ redis.service }}
    - require:
      - file_ext: {{ redis.init_location }}
  service.running:
    - name: {{ redis.service }}
{% if not is_docker() %}
    - enable: True
{% endif %}
    - watch:
      - file_ext: /etc/redis/{{ redis.service }}.conf
