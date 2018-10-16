save_container_id:
  salt.runner:
    - name: sdb.set
    - uri: sdb://mastercache/docker_events_{{ pillar['data']['data']['Actor']['Attributes']['io.kubernetes.pod.name'] }}_container_id
    - value: {{ pillar['data']['data']['Actor']['ID'] }}

save_minion_id:
  salt.runner:
    - name: sdb.set
    - uri: sdb://mastercache/docker_events_{{ pillar['data']['data']['Actor']['Attributes']['io.kubernetes.pod.name'] }}_minion_id
    - value: {{ pillar['data']['id'] }}


redis_ready_to_orchestrate_pre:
  salt.runner:
  - name: event.send
  - tag: 'salt/orchestrate/redis/pre'
  - data:
      lhs: {{ pillar['data']['data']['Actor']['Attributes']['io.kubernetes.pod.name'].split('-')|last }}
      rhs: {{ pillar['redis']['size'] }}

{% if pillar['data']['data']['Actor']['Attributes']['io.kubernetes.pod.name'].split('-')|last|int == pillar['redis']['size']|int %}
redis_ready_to_orchestrate:
  salt.runner:
    - name: event.send
    - tag: 'salt/orchestrate/redis/ready'
    - data:
        todo: "iterate and fetch instances from sdb"
    - require:
        - salt: save_minion_id
        - salt: save_container_id
{% endif %}
