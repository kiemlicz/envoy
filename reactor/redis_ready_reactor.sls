redis_orchestrate:
  runner.state.orchestrate:
    - args:
      - mods:
        - redis.server._orchestrate.orchestrate
      - saltenv: server
      - pillarenv: base
