{% set event_data = pillar["docker_event"] %}
{% set pod_name = event_data['data']['Actor']['Attributes']['io.kubernetes.pod.name'] %}

refresh_pillar:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: '*'
