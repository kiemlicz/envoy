{% from "redis/server/cluster/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set this_host = grains['id'] %}
{% set all_instances = redis.masters + redis.slaves %}

{% for instance in all_instances|selectattr("id", "equalto", this_host)|list %}

{% set instance_ip = ip() %}
redis_{{ instance.ip }}_{{ instance.port }}_cluster_reset:
  cmd.run:
    - name: redis-cli -h {{ instance_ip }} -p {{ instance.port }} CLUSTER RESET

{% endfor %}
