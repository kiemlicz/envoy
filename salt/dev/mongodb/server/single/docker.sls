{% from "mongodb/server/single/map.jinja" import mongodb with context %}
{% from "mongodb/server/macros.jinja" import mongodb_docker_prerequisites with context %}
{% from "mongodb/server/macros.jinja" import mongodb_docker with context %}
{% from "_common/ip.jinja" import ip with context %}


{% set bind = {
  'port': mongodb.port,
  'ip': mongodb.ip|default(ip())
} %}

include:
  - pkgs

{{ mongodb_docker_prerequisites(mongodb) }}
{{ mongodb_docker(mongodb, bind) }}
