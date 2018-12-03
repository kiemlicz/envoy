redis_orchestrate:
  runner.state.orchestrate:
    - args:
      - mods:
        - redis._orch.orchestrate
      - saltenv: server
      - pillarenv: base
