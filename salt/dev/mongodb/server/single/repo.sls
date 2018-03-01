{% from "mongodb/server/single/map.jinja" import mongodb with context %}
{% from "mongodb/server/macros.jinja" import mongodb_install with context %}
{% from "mongodb/server/macros.jinja" import mongodb_configure with context %}

{% set bind = {
  'ip': mongodb.ip,
  'port': mongodb.port
} %}

include:
  - pkgs

#mongodb client is installed without adding mongodb repo - thus causes conflicts with official mongo repo
exclude:
  - id: mongodb_client

{{ mongodb_install(mongodb) }}
{{ mongodb_configure(mongodb, bind) }}
