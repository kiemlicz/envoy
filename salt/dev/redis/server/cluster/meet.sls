{% from "redis/server/cluster/map.jinja" import redis with context %}
{% from "redis/server/cluster/map.jinja" import redis_cluster with context %}
{% set this_host = grains['id'] %}
{% set offset = 0 %}

{% for master in redis.master_bind_list|selectattr("host_id", "equalto", this_host)|list %}
{% set start_slot = offset %}
{% set end_slot = offset + redis_cluster.range %}

# cluster meet command could be executed on one master only
# but as we need to assign slots...
redis_master_{{ master.host }}_{{ master.port }}_cluster_meet:
  cmd.run:
    - names:
{% for other in redis.master_bind_list + redis.slave_bind_list %}
      - redis-cli -h {{ master.host }} -p {{ master.port }} CLUSTER MEET {{ other.host }} {{ other.port }}
{% endfor %}
    - runas: {{ redis.user }}

redis_master_{{ master.host }}_{{ master.port }}_assign_slots:
  cmd.run:
    - name: redis-cli -h {{ master.host }} -p {{ master.port }} CLUSTER ADDSLOTS {{ range(start_slot, end_slot)|join(" ") }}
    - require:
      - cmd: redis_master_{{ master.host }}_{{ master.port }}_cluster_meet

{% set offset = offset + redis_cluster.range %}
{% endfor %}

{# todo iterate over remaning slots and distrbute 'evenly' to the all masters #}
{% set master = redis.master_bind_list|selectattr("host_id", "equalto", this_host)|list|last %}
redis_master_{{ master.host }}_{{ master.port }}_assign_remaning_slots:
  cmd.run:
    - name: redis-cli -h {{ master.host }} -p {{ master.port }} CLUSTER ADDSLOTS {{ range(redis_cluster.total_slots - redis_cluster.remaining_slots, redis_cluster.total_slots + 1)|join(" ") }}
    - require:
      - cmd: redis_master_{{ master.host }}_{{ master.port }}_cluster_meet
