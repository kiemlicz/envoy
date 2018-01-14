{% from "redis/server/cluster/map.jinja" import redis with context %}
{% set this_host = grains['id'] %}

{% for master in redis.masters|selectattr("host_id", "equalto", this_host)|list %}

# cluster meet command could be executed on one master only
# but as we need to assign slots...
redis_master_{{ master.host }}_{{ master.port }}_cluster_meet:
  cmd.run:
    - names:
{% for other in redis.masters + redis.slaves %}
      - redis-cli -h {{ master.host }} -p {{ master.port }} CLUSTER MEET {{ other.host|dns_check(4505) }} {{ other.port }}
{% endfor %}

redis_master_{{ master.host }}_{{ master.port }}_assign_slots:
  cmd.run:
    - name: redis-cli -h {{ master.host }} -p {{ master.port }} CLUSTER ADDSLOTS {{ salt['pillar.get']('redis:slots:' + this_host)|join(" ") }}
    - require:
      - cmd: redis_master_{{ master.host }}_{{ master.port }}_cluster_meet


{% endfor %}
