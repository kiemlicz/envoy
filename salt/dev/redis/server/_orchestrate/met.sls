{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}
{% from "_common/util.jinja" import retry with context %}


redis_cluster_met:
  redis_ext.met:
    - instances: {{ redis.instances.map }}
{{ retry(attempts=3, interval=10)| indent(4) }}
