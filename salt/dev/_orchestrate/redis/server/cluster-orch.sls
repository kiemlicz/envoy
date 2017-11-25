{% from "redis/server/cluster.map.jinja" import redis with context %}
{% set all_instances = redis.master_bind_list + redis.slave_bind_list %}

{# pod spodem jest grains.get id czyli salt-run wsadzi tam ambassador.mgl_master #}
{# tgt z cmd brany #}

{% set tgts = all_instances|map(attribute='hostname')|unique|join(',') %}

redis_cluster_meet_orchestrate:
  salt.state:
    - tgt: '*'
    - sls:
      - redis.server.cluster-meet
    - saltenv: {{ saltenv }}
