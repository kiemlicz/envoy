{% from "redis/server/cluster/map.jinja" import redis with context %}
{% from "redis/server/macros.jinja" import redis_docker_prerequisites with context %}
{% from "redis/server/macros.jinja" import redis_docker with context %}

{% set this_host = grains['id'] %}
{% set all_instances = redis.masters + redis.slaves %}

{% if this_host in all_instances|map(attribute='host_id')|list %}

include:
  - pkgs

{{ redis_docker_prerequisites(redis) }}

{% for bind in all_instances|selectattr("host_id", "equalto", this_host)|list %}

{{ redis_docker(redis, bind, True) }}

{% endfor %}

{% endif %}
