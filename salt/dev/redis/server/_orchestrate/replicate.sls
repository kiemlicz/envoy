{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set slaves_list = redis.instances.get('slaves', []) %}
{% if redis.kubernetes is defined %}
  {% set nodes_map = redis.kubernetes.pods %}
{% else %}
  {% set nodes_map = {} %}
  {% for instance in redis.instances.masters + redis.instances.slaves %}
    {% do nodes_map.update({ instance['name']: {
        'ips': [ instance.ip|default(ip(id=instance.name)) ],
        'port': instance.port,
      }
    }) %}
  {% endfor %}
{% endif %}

redis_cluster_replicate:
  redis_ext.replicate:
    - name: redis_cluster_replicate
    - nodes_map: {{ nodes_map }}
    - slaves_list: {{ slaves_list }}
