#unused only for testing and further research purposes
redis_cluster_meet:
  local.state.apply:
    - tgt: '*'
    - args:
      - mods: redis.server.cluster-meet
      - saltenv: dev

