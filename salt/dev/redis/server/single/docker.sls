{% from "redis/server/single/map.jinja" import redis with context %}
{% from "redis/server/macros.jinja" import redis_docker_prerequisites with context %}
{% from "redis/server/macros.jinja" import redis_docker with context %}
{% from "docker/map.jinja" import docker with context %}

{% set bind = {
  'host': redis.host,
  'port': redis.port
} %}

include:
  - pkgs

{{ redis_docker_prerequisites(redis) }}
{{ redis_docker(redis, bind, False) }}
