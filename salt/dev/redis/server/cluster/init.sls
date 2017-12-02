{% from "redis/server/cluster/map.jinja" import redis with context %}
{% set this_host = grains['id'] %}
{% set all_instances = redis.master_bind_list + redis.slave_bind_list %}

{% if this_host in all_instances|map(attribute='host_id')|list %}

include:
  - redis.server.single.install

{% for bind in all_instances|selectattr("host_id", "equalto", this_host)|list %}
{% set instance = redis.name + '-' + bind.port|string %}

redis_config_{{ bind.host }}_{{ bind.port }}:
  file_ext.managed:
    - name: /etc/redis/{{ instance }}.conf
    - source: {{ redis.config }}
    - makedirs: True
    - template: jinja
    - context:
      bind: {{ bind }}
    - require:
      - file_ext: {{ redis.init_location }}
  service.running:
    - name: {{ redis.service }}@{{ instance }}
    - enable: True
    - require:
      - file_ext: /etc/redis/{{ instance }}.conf

{% endfor %}

{% endif %}
