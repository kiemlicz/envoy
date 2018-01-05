# if enumerating orchestrators in mods won't be sufficient then create root orchestrator
# with clean requisite statements etc.

start_orchestration:
  runner.state.orchestrate:
    - args:
      - mods:
        - _orchestrate.redis.server.cluster.orch
      - saltenv: {{ saltenv }}
