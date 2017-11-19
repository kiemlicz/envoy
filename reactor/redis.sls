redis_cluster_meet:
  local.state.apply:
    - tgt: '*'
    - args:
      - mods: redis.server.cluster-meet
      - saltenv: dev
      - pillar:
          event_tag: {{ tag }}
          event_data: {{ data|json }}
