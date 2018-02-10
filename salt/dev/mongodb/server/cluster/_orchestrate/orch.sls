{% from "mongodb/server/cluster/map.jinja" import mongodb with context %}

{% set master = mongodb.replicas|selectattr('master', 'defined')|first %}

mongodb_replica_set:
  salt.state:
    - tgt: {{ master.host }}
    - sls:
      - "mongodb.server.cluster._orchestrate.replicate"
    - saltenv: {{ saltenv }}
    - pillar:
        master: {{ master }}
