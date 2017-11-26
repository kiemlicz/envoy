redis_cluster_meet_orchestrate:
  salt.state:
    - tgt: '*'
    - sls:
      - redis.server.cluster.meet
      - redis.server.cluster.replicate
    - saltenv: {{ saltenv }}
