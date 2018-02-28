{% from "redis/server/macros.jinja" import redis_master_id with context %}
{% from "redis/server/cluster/map.jinja" import redis with context %}
{% set this_host = grains['id'] %}

{% for slave in redis.slaves|selectattr("id", "equalto", this_host)|list %}
{% set master_id = redis_master_id(slave.master_ip, slave.master_port) %}

redis_slave_{{ slave.ip }}_{{ slave.port }}_replicate_master:
  cmd.run:
    - name: redis-cli -h {{ slave.ip }} -p {{ slave.port }} CLUSTER REPLICATE {{ master_id }}

{% endfor %}
