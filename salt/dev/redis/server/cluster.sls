{% from "redis/server/cluster.map.jinja" import redis with context %}
{% set this_host = grains['id'] %}
{% set all_instances = redis.master_bind_list + redis.slave_bind_list %}

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


{% for bind in all_instances|selectattr("hostname", "equalto", this_host)|list %}
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

# meet
# alloc slots
# event send to slave ?

{% endfor %}
