{% from "mongodb/server/cluster/map.jinja" import mongodb with context %}

{% set replica_initializer = mongodb.replicas|selectattr('init')|first %}

mongodb_replica_set:
  salt.state:
    - tgt: {{ replica_initializer.host }}
    - sls:
      - "mongodb.server.cluster._orchestrate.replicate"
    - saltenv: saltenv
    - pillar:
        initializer: {{ replica_initializer }}
