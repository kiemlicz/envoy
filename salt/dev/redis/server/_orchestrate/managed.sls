{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set desired_masters = redis.instances.get('masters', [])|map(attribute='name')|list %}
{% set slaves_list = redis.instances.get('slaves') %}
{% set masters_list = redis.instances.get('masters') %}
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
    - slaves_list: {{ slaves_list }}
    - masters_list: {{ masters_list }}
    - replication_factor: {{ redis.replication_factor }}

redis_cluster_balanced:
  redis_ext.balanced:
  - nodes: {{ nodes_map }}
  - desired_masters: {{ desired_masters }}
  - total_slots: {{ redis.total_slots }}
  - require:
      - redis_ext: redis_cluster_replicated
