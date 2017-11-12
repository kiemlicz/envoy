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

redis_config:
  file_ext.managed:
    - name: /etc/redis/{{ redis.name }}-{{ bind.port }}.conf
    - source: {{ redis.config }}
    - makedirs: True
    - template: jinja
    - context:
      bind: {{ bind }}
    - require:
      - file_ext: {{ redis.init_location }}
  service.running:
    - name: {{ redis.service }}@{{ redis.name }}-{{ bind.port }}
    - enable: True
    - require:
      - file_ext: /etc/redis/{{ redis.name }}-{{ bind.port }}

{% endfor %}
