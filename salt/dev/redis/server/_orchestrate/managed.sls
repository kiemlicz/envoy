{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set desired_masters = redis.instances.get('masters', [])|map(attribute='name')|list %}
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

# todo migrate separately


# size assert could be placed in jinja here as well

cluster_manage:
  redis_ext.managed:
  - nodes: {{ nodes_map }}
  - min_nodes: {{ size }}
  - desired_masters: {{ desired_masters }}
  - total_slots: {{ redis.total_slots }}
