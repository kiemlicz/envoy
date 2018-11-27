{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}
{% from "_common/util.jinja" import retry with context %}


{% set slaves_list = redis.instances.slaves %}
{% set masters_list = redis.instances.masters %}

# size assert could be placed in jinja here as well

redis_cluster_replicated:
  redis_ext.replicated:
    - instances: {{ redis.instances.map }}
  {% if slaves_list is defined and masters_list is defined %}
    - slaves_list: {{ slaves_list }}
    - masters_list: {{ masters_list }}
  {% endif %}
    - replication_factor: {{ redis.replication_factor }}
{{ retry(attempts=3, interval=10)| indent(4) }}

redis_cluster_balanced:
  redis_ext.balanced:
    - instances: {{ redis.instances.map }}
    {% if slaves_list is defined and masters_list is defined %}
    - desired_masters: {{ masters_list }}
    {% endif %}
    - total_slots: {{ redis.total_slots }}
{{ retry(attempts=3, interval=10)| indent(4) }}
    - require:
      - redis_ext: redis_cluster_replicated
