{% from "redis/server/cluster.map.jinja" import redis with context %}
{% from "redis/server/cluster.map.jinja" import redis_cluster with context %}

{% set this_host = grains['id'] %}

{% for master in redis.master_bind_list|selectattr("hostname", "equalto", this_host)|list %}

# cluster meet command could be executed on one master only
# but as we need to assign slots...
redis_master_{{ master.host }}_{{ master.port }}_cluster_meet:
  cmd.run:
    - names:
{% for other in redis.master_bind_list %}
      - redis-cli -h {{ master.host }} -p {{ master.port }} CLUSTER MEET {{ other.host }} {{ other.port }}
{% endfor %}
    - runas: {{ redis.user }}

redis_master_{{ master.host }}_{{ master.port }}_assign_slots:
  cmd.run:
    - name: redis-cli -h {{ master.host }} -p {{ master.port }} CLUSTER ADDSLOTS {{ redis_cluster.range }}
    - require:
      - cmd: redis_master_{{ master.host }}_{{ master.port }}_cluster_meet

{% endfor %}

{% for slave in redis.slave_bind_list|selectattr("hostname", "equalto", this_host)|list %}

redis_slave_{{ slave.host }}_{{ slave.port }}_replicate_master:
  cmd.run:
    - name: redis-cli -h {{ slave.host }} -p {{ slave.port }} CLUSTER REPLICATE {{ slave.master_id }}

{% endfor %}
