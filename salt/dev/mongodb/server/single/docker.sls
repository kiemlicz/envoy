{% from "mongodb/server/single/map.jinja" import mongodb with context %}
{% from "mongodb/server/macros.jinja" import mongodb_docker_prerequisites with context %}
{% from "mongodb/server/macros.jinja" import mongodb_docker with context %}
{% from "docker/map.jinja" import docker with context %}

{{ mongodb_docker_prerequisites(mongodb) }}
{{ mongodb_docker(mongodb) }}
