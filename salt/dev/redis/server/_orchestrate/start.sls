{% set event_data = pillar["docker_event"] %}
{% set event_sender = event_data['data']['id'] %}
{% set pod_name = event_data['data']['Actor']['Attributes']['io.kubernetes.pod.name'] %}

refresh_pillar:
    salt.function:
        - name: saltutil.refresh_pillar
        - tgt: {{ event_sender }}

pod_started:
  salt.runner:
    - name: event_ext.send_when
    - tag: 'salt/orchestrate/redis/ready'
    - condition: __slot__:salt:condition.pillar_eq("redis:kubernetes:spec:replicas", "redis:kubernetes:status:readyReplicas")
    - data:
        redis:
            coordinator: {{ event_sender }}
    - require:
        - salt: refresh_pillar
