{% from "redis/server/cluster.map.jinja" import redis with context %}

redis_pkg:
  pkg.latest:
    - name: {{ redis.pkg_name }}
    - require:
      - pkg: os_packages
# for systemd uses %i variable that allows multiple instances per node
  file_ext.managed:
    - name: {{ redis.init_location }}
    - source: {{ redis.init }}
    - require:
      - pkg: {{ redis.pkg_name }}

{% for bind in redis.bind_list %}
{% set instance = redis.name + '-' + bind.port %}

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
