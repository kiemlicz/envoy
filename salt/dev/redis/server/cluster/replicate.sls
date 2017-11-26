{% from "redis/server/cluster/map.jinja" import redis with context %}
{% set this_host = grains['id'] %}

{% for slave in redis.slave_bind_list|selectattr("host_id", "equalto", this_host)|list %}

redis_slave_{{ slave.host }}_{{ slave.port }}_replicate_master:
  cmd.run:
    - name: redis-cli -h {{ slave.host }} -p {{ slave.port }} CLUSTER REPLICATE {{ slave.master_id }}

{% endfor %}