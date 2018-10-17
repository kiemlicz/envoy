add_to_mine:
  salt.function:
  - name: mine.send
  - tgt: {{ pillar['data']['id'] }}
  - arg:
    - {{ pillar['data']['data']['Actor']['Attributes']['io.kubernetes.pod.name'] }}
  - kwarg:
      mine_function: docker.inspect
      name: {{ pillar['data']['data']['Actor']['ID'] }}

{% set replicas = pillar['data']['data']['Actor']['Attributes']['io.kubernetes.pod.name'].split(pillar['kube']['delim'])|last|int %}
{% if replicas == pillar['redis']['size']|int %}
redis_ready_to_orchestrate:
  salt.runner:
    - name: event.send
    - tag: 'salt/orchestrate/redis/init'
    - data:
        app: {{ pillar['data']['data']['Actor']['Attributes']['io.kubernetes.pod.name'].split(pillar['kube']['delim'])[:-1]|join(pillar['kube']['delim']) }}
        replicas: {{ replicas }}
    - require:
        - salt: add_to_mine
{% endif %}
