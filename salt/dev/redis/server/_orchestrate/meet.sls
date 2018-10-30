{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set this_host = grains['id'] %}

{% if redis.docker is defined %}
  {% set nodes_map = salt['kube_ext.app_info']("redis-cluster") %}
  {% for k in nodes_map %}
    {% do nodes_map[k].update({'port': redis.port}) %}
  {% endfor %}
{% else %}
  {% set nodes_map = {} %}
  {% for instance in redis.masters + redis.slaves %}
    {% do nodes_map.update({ instance['id']: {
        'ips': [ instance.ip|default(ip(id=instance.id)) ],
        'port': instance.port,
        'minion': instance.id,
      }
    }) %}
  {% endfor %}
{% endif %}

redis_cluster_meet:
  redis_ext.meet:
    - name: redis_cluster_meet
    - nodes_map: {{ nodes_map }}
