{% from "redis/server/single/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}
{% from "_common/util.jinja" import is_docker with context %}


{% set bind = {
  'port': redis.port,
  'ip': redis.ip|default(ip())
} %}

redis_config_{{ bind.ip }}_{{ bind.port }}:
  file_ext.managed:
    - name: /etc/redis/{{ redis.config.service }}.conf
    - source: {{ redis.config.source }}
    - makedirs: True
    - template: jinja
    - context:
      bind: {{ bind|json_decode_dict }}
      redis: {{ redis|json_decode_dict }}
      discriminator: {{ redis.pkg_name }}  # by default redis-server looks for pidfile with name: redis-server.pid
    - require:
      - pkg: {{ redis.pkg_name }}
  service.running:
    - name: {{ redis.config.service }}
{% if not is_docker() %}
    - enable: True
{% endif %}
    - watch:
      - file_ext: /etc/redis/{{ redis.config.service }}.conf
