{% from "mongodb/server/cluster/map.jinja" import mongodb with context %}
{% from "mongodb/server/macros.jinja" import mongodb_docker_prerequisites with context %}
{% from "mongodb/server/macros.jinja" import mongodb_docker with context %}

{% set this_host = grains['id'] %}
{% set all_instances = mongodb.shards + mongodb.replicas %}

{% if this_host in all_instances|map(attribute='id')|list %}

include:
  - pkgs

{{ mongodb_docker_prerequisites(mongodb) }}

{% for bind in all_instances|selectattr("id", "equalto", this_host)|list %}

{{ mongodb_docker(mongodb, bind) }}

{% endfor %}

{% endif %}
