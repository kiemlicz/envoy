{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set masters_names = redis.instances.get('masters', [])|map(attribute='name')|list %}
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

redis_cluster_slots_manage:
  redis_ext.managed:
    - name: redis_cluster_slots_manage
    - nodes_map: {{ nodes_map }}
    - min_nodes: {{ size }}
    - master_names: {{ masters_names }}
    - total_slots: {{ redis.total_slots }}
