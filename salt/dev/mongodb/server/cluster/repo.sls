{% from "mongodb/server/cluster/map.jinja" import mongodb with context %}
{% from "mongodb/server/macros.jinja" import mongodb_install with context %}
{% from "mongodb/server/macros.jinja" import mongodb_configure with context %}

{% set this_host = grains['id'] %}
{% set all_instances = mongodb.replicas + mongodb.shards %}

{% if this_host in all_instances|map(attribute='host_id')|list %}

include:
  - pkgs

{{ mongodb_install(mongodb) }}

{% for bind in all_instances|selectattr("host_id", "equalto", this_host)|list %}

{{ mongodb_configure(mongodb, bind) }}

{% endfor %}

{% endif %}
