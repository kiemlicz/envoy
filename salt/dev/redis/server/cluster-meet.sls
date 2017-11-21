{% from "redis/server/cluster.map.jinja" import redis with context %}

{% set this_host = grains['host'] %}

{% for bind in redis.bind_list|selectattr("hostname", this_host)|list %}

# cluster meet command could be executed on one master only
# but as we need to assign slots...
redis_cluster_meet_masters:
  cmd.run:
    - names:
{% for other in redis.bind_list %}
      - redis-cli -p {{ bind.port }} CLUSTER MEET {{ other.host }} {{ other.port }}
{% endfor %}
    - runas: {{ redis.user }}

redis_cluster_assign_slots:
  cmd.run:
    - name:

{% endfor %}
