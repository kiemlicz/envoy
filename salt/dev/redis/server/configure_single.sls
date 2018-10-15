{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set bind = {
  'port': redis.port,
  'ip': redis.ip|default(ip())
} %}

redis_config_{{ bind.ip }}_{{ bind.port }}:
  file_ext.managed:
    - name: {{ redis.config.conf_file }}
    - source: {{ redis.config.source }}
    - makedirs: True
    - template: jinja
    - context:
      bind: {{ bind|json_decode_dict }}
      redis: {{ redis|json_decode_dict }}
    - require:
      - pkg: {{ redis.pkg_name }}
  service.running:
    - name: {{ redis.config.service }}
    - enable: True
    - watch:
      - file_ext: {{ redis.config.conf_file }}
