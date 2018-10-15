{% from "redis/server/macros.jinja" import redis_master_id with context %}
{% from "redis/server/cluster/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set this_host = grains['id'] %}

{% for slave in redis.slaves|selectattr("id", "equalto", this_host)|list %}
{% set slave_ip = slave.ip|default(ip()) %}
{% set master_ip = slave.of_master.ip|default(ip(id=slave.of_master.id)) %}
{% set redis_master_id = redis_master_id(master_ip, slave.of_master.port) %}

redis_slave_{{ slave_ip }}_{{ slave.port }}_replicate_master:
  cmd.run:
    - name: redis-cli -h {{ slave_ip }} -p {{ slave.port }} CLUSTER REPLICATE {{ redis_master_id }}

{% endfor %}
