{% from "mongodb/server/cluster/map.jinja" import mongodb with context %}

# todo rewrite to py, import jinja
{% set replicas = [] %}
{% set id = 0 %}
{% for replica in mongodb.replicas %}
{% set r = {
  'id': id,
  'host': replica.host + ":" + replica.port
} %}
{% do replicas.append(r) %}
{% set id = id + 1 %}
{% endfor %}

# according to https://docs.mongodb.com/manual/tutorial/deploy-replica-set/
# this state must execute on one minion only
mongodb_initiate_replica_set:
  cmd.run:
    - name: mongo --host {{ initializer.host }} --port {{ initializer.port }} --eval 'rs.initiate({ _id: {{ initializer.replica_name }}, members: {{ replicas }} })'
