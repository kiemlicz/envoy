{% from "redis/server/cluster/map.jinja" import redis with context %}

{% set this_host = grains['id'] %}
{% set all_instances = redis.master_bind_list + redis.slave_bind_list %}

{% for instance in all_instances|selectattr("host_id", "equalto", this_host)|list %}

redis_{{ instance.host }}_{{ instance.port }}_cluster_reset:
  cmd.run:
    - name: redis-cli -h {{ instance.host }} -p {{ instance.port }} CLUSTER RESET

{% endfor %}
