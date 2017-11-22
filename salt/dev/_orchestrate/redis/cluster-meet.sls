{% from "redis/server/cluster.map.jinja" import redis with context %}

redis_cluster_meet_orchestrate:
  salt.state:
    - tgt: {{ redis.master_bind_list|map(attribute='hostname')|join(',') }}
    - sls:
      - redis.server.cluster-meet

