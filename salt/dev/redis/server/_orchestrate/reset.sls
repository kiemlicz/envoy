{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


redis_cluster_reset:
  redis_ext.reset:
    - name: redis_cluster_reset
    - instances: {{ redis.instances.map }}
