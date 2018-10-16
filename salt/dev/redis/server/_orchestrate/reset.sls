{% from "redis/server/map.jinja" import redis with context %}
{% from "_common/ip.jinja" import ip with context %}

#accept extra args from orchestrator, just pass pillar - it should just work
{% set this_host = grains['id'] %}
{% set all_instances = redis.masters + redis.slaves %}

{% for instance in all_instances|selectattr("id", "equalto", this_host)|list %}

{% set instance_ip = instance.ip|default(ip()) %}
redis_{{ instance_ip }}_{{ instance.port }}_cluster_reset:
  cmd.run:
    - name: redis-cli -h {{ instance_ip }} -p {{ instance.port }} CLUSTER RESET

{% endfor %}
