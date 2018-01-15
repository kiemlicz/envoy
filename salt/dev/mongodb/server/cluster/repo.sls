{% from "mongodb/server/cluster/map.jinja" import mongodb with context %}
{% from "mongodb/server/macros.jinja" import mongodb_install with context %}

include:
  - pkgs

{{ mongodb_install(mongodb) }}
