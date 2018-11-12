#wait_for_all_instances:
#  salt.wait_for_event:
#    - name: salt/redis/kubernetes/*
#    - id_list:
#        - redis-cluster-0
#        - redis-cluster-1
#        - redis-cluster-2
#        - redis-cluster-3
#    - event_id:
#        - pod_name
# todo pillar.get size and create list here in jinja, this would be safe
# todo add onfail

cluster_met:
  salt.state:
    - tgt: "redis:coordinator:True"
    - tgt_type: pillar
    - sls:
        - redis.server._orchestrate.met
    - saltenv: {{ saltenv }}
    - pillarenv: {{ pillarenv }}
    - require:
        - salt: refresh_pillar

cluster_managed:
  salt.state:
    - tgt: "redis:coordinator:True"
    - tgt_type: pillar
    - sls:
        - redis.server._orchestrate.managed
    - saltenv: {{ saltenv }}
    - pillarenv: {{ pillarenv }}
    - require:
        - salt: cluster_meet
