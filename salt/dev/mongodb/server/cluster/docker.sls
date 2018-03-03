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

{% set ip_addrs = salt['mine.get'](bind.id, 'network.ip_addrs') %}
{% do bind.update({
  "ip_addrs": ip_addrs.values(),
  "ip": bind.ip|default(ip_addrs.values()[0])
}) %}

{{ mongodb_docker(mongodb, bind) }}

{% endfor %}

{% endif %}
