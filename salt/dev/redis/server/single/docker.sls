{% from "redis/server/single/map.jinja" import redis with context %}
{% from "redis/server/macros.jinja" import redis_docker_prerequisites with context %}
{% from "redis/server/macros.jinja" import redis_docker with context %}
{% from "docker/map.jinja" import docker with context %}
{% from "_common/ip.jinja" import ip with context %}

{% set bind = {
  'port': redis.port,
  'ip': redis.ip|default(ip())
} %}

include:
  - pkgs

{{ redis_docker_prerequisites(redis) }}
{{ redis_docker(redis, bind) }}
