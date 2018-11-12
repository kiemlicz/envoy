{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set slaves_list = redis.instances.slaves %}
{% set masters_list = redis.instances.masters %}
{% if redis.kubernetes is defined %}
  {% set size = redis.kubernetes.status.replicas %}
  {% set nodes_map = redis.kubernetes.pods %}
{% else %}
  {% set size = (redis.instances.masters + redis.instances.slaves)|length %}
  {% set nodes_map = {} %}
  {% for instance in (redis.instances.masters + redis.instances.slaves) %}
    {% do nodes_map.update({ instance['name']: {
        'ips': [ instance.ip|default(ip(id=instance.name)) ],
        'port': instance.port,
      }
    }) %}
  {% endfor %}
{% endif %}

# size assert could be placed in jinja here as well

redis_cluster_replicated:
  redis_ext.replicated:
    - nodes: {{ nodes_map }}
  {% if slaves_list is defined and masters_list is defined %}
    - slaves_list: {{ slaves_list }}
    - masters_list: {{ masters_list }}
  {% endif %}
    - replication_factor: {{ redis.replication_factor }}

redis_cluster_balanced:
  redis_ext.balanced:
    - nodes: {{ nodes_map }}
    {% if slaves_list is defined and masters_list is defined %}
    - desired_masters: {{ masters_list }}
    {% endif %}
    - total_slots: {{ redis.total_slots }}
    - retry:
        until: True
        attempts: 2
        interval: 5
        splay: 10
    - require:
      - redis_ext: redis_cluster_replicated
