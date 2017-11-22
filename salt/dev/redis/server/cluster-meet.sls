{% from "redis/server/cluster.map.jinja" import redis with context %}
{% from "redis/server/cluster.map.jinja" import redis_cluster with context %}

{% set this_host = grains['host'] %}

{% for bind in redis.master_bind_list|selectattr("hostname", "equalto", this_host)|list %}

# cluster meet command could be executed on one master only
# but as we need to assign slots...
redis_master_{{ bind.host }}_{{ bind.port }}_cluster_meet:
  cmd.run:
    - names:
{% for other in redis.master_bind_list %}
      - redis-cli -p {{ bind.port }} CLUSTER MEET {{ other.host }} {{ other.port }}
{% endfor %}
    - runas: {{ redis.user }}

redis_master_{{ bind.host }}_{{ bind.port }}_assign_slots:
  cmd.run:
    - name: redis-cli -p {{ bind.port }} CLUSTER ADDSLOTS {{ redis_cluster.range }}
    - require:
      - cmd: redis_master_{{ bind.host }}_{{ bind.port }}_cluster_meet

{% endfor %}
