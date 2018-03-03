{% from "mongodb/server/single/map.jinja" import mongodb with context %}
{% from "mongodb/server/macros.jinja" import mongodb_install with context %}
{% from "mongodb/server/macros.jinja" import mongodb_configure with context %}

{#todo move to macro# }
{% set ip_addrs = salt['mine.get'](mongodb.id, 'network.ip_addrs') %}
{% set bind = {
  'ip_addrs': ip_addrs.values(),
  'ip': mongodb.ip|default(ip_addrs.values()[0]),
  'port': mongodb.port
} %}

include:
  - pkgs

#mongodb client is installed without adding mongodb repo - thus causes conflicts with official mongo repo
exclude:
  - id: mongodb_client

{{ mongodb_install(mongodb) }}
{{ mongodb_configure(mongodb, bind) }}
