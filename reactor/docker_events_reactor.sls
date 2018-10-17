{% if data['data']['status'] == 'start' and
  data['data']['Actor']['Attributes']['io.kubernetes.pod.name'] is match('redis-cluster-[\d+]') and
  data['data']['Actor']['Attributes']['io.kubernetes.docker.type'] == "container"
  %}

wait_for_redis:
  runner.state.orchestrate:
    - args:
      - mods:
        - redis.server._orchestrate.wait_for_redis
      - saltenv: server
      - pillar:
          data: {{ data|json_encode_dict }}
          redis:
            size: 3
          kube:
            delim: "-"
{% endif %}
