redis_cluster_orchestrate:
  salt.state:
    - tgt: {{ salt['pillar.get']("redis_minions") }}
    - tgt_type: list
    - sls:
      - redis.server.cluster.reset
      - redis.server.cluster.meet
      - redis.server.cluster.replicate
    - saltenv: {{ saltenv }}
