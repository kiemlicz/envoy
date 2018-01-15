{% from "mongodb/server/single/map.jinja" import mongodb with context %}
{% from "mongodb/server/macros.jinja" import mongodb_install with context %}
{% from "mongodb/server/macros.jinja" import mongodb_configure with context %}

{% set bind = {
  'host': mongodb.host,
  'port': mongodb.port
} %}

include:
  - pkgs

{{ mongodb_install(mongodb) }}
{{ mongodb_configure(mongodb, bind) }}
