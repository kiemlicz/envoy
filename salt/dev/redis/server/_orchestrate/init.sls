refresh_pillar:
    salt.function:
    - name: saltutil.pillar_refresh
    - tgt: {{ salt['pillar.get']("redis:coordinator") }}

# todo sls together in one list? How do they handle failures?

cluster_met:
    salt.state:
    - tgt: {{ salt['pillar.get']("redis:coordinator") }}
    - sls:
      - "redis.server._orchestrate.met"
    - queue: True
    - saltenv: {{ saltenv }}
    - require:
      - salt: refresh_pillar

cluster_managed:
    salt.state:
    - tgt: {{ salt['pillar.get']("redis:coordinator") }}
    - sls:
      - "redis.server._orchestrate.managed"
    - queue: True
    - saltenv: {{ saltenv }}
    - require:
      - salt: cluster_met

notify_success:
    salt.runner:
    - name: event.send
    - tag: 'salt/orchestrate/redis/success'
    - data: {}
    - require:
      - salt: cluster_managed

notify_fail:
    salt.runner:
    - name: event.send
    - tag: 'salt/orchestrate/redis/failure'
    - data: {}
    - onfail_any:
      - salt: cluster_met
      - salt: cluster_managed
