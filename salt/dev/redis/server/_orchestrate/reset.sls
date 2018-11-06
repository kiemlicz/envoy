{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set masters_names = redis.instances.get('masters', [])|map(attribute='name')|list %}
{% if redis.kubernetes is defined %}
  {% set nodes_map = redis.kubernetes.pods %}
{% else %}
  {% set nodes_map = {} %}
  {% for instance in (redis.instances.masters + redis.instances.slaves) %}
    {% do nodes_map.update({ instance['name']: {
      'ips': [ instance.ip|default(ip(id=instance.name)) ],
      'port': instance.port,
      }
    }) %}
  {% endfor %}
{% endif %}

redis_cluster_reset:
  redis_ext.reset:
    - name: redis_cluster_reset
    - nodes: {{ nodes_map }}
    - masters_names: {{ masters_names }}
