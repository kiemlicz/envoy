{% if data['data']['status'] == 'start' and data['data']['Actor']['Attributes']['io.kubernetes.pod.name'] == "redis-cluster-2" %}

redis_orchestrate:
  runner.state.orchestrate:
  - args:
    - mods:
      - redis.server.cluster._orchestrate.orch

{% endif %}
