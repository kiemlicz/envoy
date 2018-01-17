{% from "mongodb/server/cluster/map.jinja" import mongodb with context %}

{% set replicas = mongodb.replicas|map(attribute='host_id')|list %}

mongodb_replica_set:
  salt.state:
    - tgt: {{ replicas }}
    - tgt_type: "list"
    - sls:
      - "mongodb.server.cluster._orchestrate.replicate"
    - saltenv: saltenv
