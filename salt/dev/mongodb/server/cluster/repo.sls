{% from "mongodb/server/cluster/map.jinja" import mongodb with context %}
{% from "mongodb/server/macros.jinja" import mongodb_install with context %}
{% from "mongodb/server/macros.jinja" import mongodb_configure with context %}

{% set this_host = grains['id'] %}
{% set all_instances = mongodb.replicas + mongodb.shards %}

{% if this_host in all_instances|map(attribute='id')|list %}

include:
  - pkgs

#mongodb client is installed without adding mongodb repo - thus causes conflicts with official mongo repo
exclude:
  - id: mongodb_client

{{ mongodb_install(mongodb) }}

{% for bind in all_instances|selectattr("id", "equalto", this_host)|list %}

{% set ip_addrs = salt['mine.get'](bind.id, 'network.ip_addrs') %}
{% do bind.update({
  "ip_addrs": ip_addrs.values(),
  "ip": bind.ip|default(ip_addrs.values()[0])
}) %}

{{ mongodb_configure(mongodb, bind) }}

{% endfor %}

{% endif %}
