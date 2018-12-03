{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}
{% from "_common/util.jinja" import retry with context %}


{% if salt.redis_ext.validate_slots(redis.instances.map) %}

redis_cluster_met:
  redis_ext.met:
    - instances: {{ redis.instances.map }}
{{ retry(attempts=3, interval=10)| indent(4) }}

{% else %}

# e.g. someone is joining old masters with some state
# don't attempt to recover this situation automatically
inconsistent_cluster:
  test.fail_without_changes:
    - name: Cluster slots overlap

{% endif %}
