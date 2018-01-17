{% from "mongodb/server/single/map.jinja" import mongodb with context %}
{% from "mongodb/server/macros.jinja" import mongodb_docker_prerequisites with context %}
{% from "mongodb/server/macros.jinja" import mongodb_docker with context %}

{% set bind = {
  'host': mongodb.host,
  'port': mongodb.port
} %}

include:
  - pkgs

{{ mongodb_docker_prerequisites(mongodb) }}
{{ mongodb_docker(mongodb, bind) }}
