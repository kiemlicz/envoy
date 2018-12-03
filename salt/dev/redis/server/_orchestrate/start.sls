{% set event_data = pillar["docker_event"] %}
{% set pod_name = event_data['data']['Actor']['Attributes']['io.kubernetes.pod.name'] %}

#remove this jinja refresh and use slots maybe?
#trick... to have fresh pillar in jinja phase
  # it won't work as tempating won't wait for refresh to complete
  # ONLY SLOTS are the way to go
  {# {%- do salt.log.info("BEFORE REFRESH") %} #}
  {# {%- do salt.saltutil.refresh_pillar() %} #}
  {# {%- do salt.log.info("AFTER REFRESH") %} #}
refresh_pillar:
    salt.function:
        - name: saltutil.refresh_pillar
        - tgt: '*'

# in order to access this fresh pillar we have to use slots
# create runner module: event.send_when

# actually it is true only one in invocation chain... but we don't care and respect multiple
{# {% if salt['pillar.get']("redis:kubernetes:spec:replicas") == salt['pillar.get']("redis:kubernetes:status:readyReplicas") %} #}

pod_started:
  salt.runner:
    - name: event_ext.send_when
    - tag: 'salt/orchestrate/redis/ready'
    - condition: __slot__:salt:condition.pillar_eq("redis:kubernetes:spec:replicas", "redis:kubernetes:status:readyReplicas")
    - data: {}
#        instance: {{ pod_name }}
#        instances_count: {{ salt['pillar.get']("redis:kubernetes:spec:replicas") }}
#        generation: {{ salt['pillar.get']("redis:kubernetes:status:observedGeneration") }}
#        someField: __slot__:salt:pillar.get("redis:kubernetes:spec:replicas")
    - require:
        - salt: refresh_pillar
