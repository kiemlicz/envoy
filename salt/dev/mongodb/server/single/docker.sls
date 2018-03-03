{% from "mongodb/server/single/map.jinja" import mongodb with context %}
{% from "mongodb/server/macros.jinja" import mongodb_docker_prerequisites with context %}
{% from "mongodb/server/macros.jinja" import mongodb_docker with context %}

{% set ip_addrs = salt['mine.get'](mongodb.id, 'network.ip_addrs') %}
{% set bind = {
  'ip_addrs': ip_addrs.values(),
  'ip': mongodb.ip|default(ip_addrs.values()[0]),
  'port': mongodb.port
} %}

include:
  - pkgs

{{ mongodb_docker_prerequisites(mongodb) }}
{{ mongodb_docker(mongodb, bind) }}
