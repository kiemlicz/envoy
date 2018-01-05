{% set masters = salt['pillar.get']("redis:master_bind_list")|map(attribute="host_id")|list %}
{% set slaves = salt['pillar.get']("redis:slave_bind_list")|map(attribute="host_id")|list %}
{% set redis_minions = (masters + slaves)|unique %}

redis_cluster_orchestrate:
  salt.state:
    - tgt: {{ redis_minions }}
    - tgt_type: list
    - sls:
      - redis.server.cluster.reset
      - redis.server.cluster.meet
      - redis.server.cluster.replicate
    - saltenv: {{ saltenv }}
