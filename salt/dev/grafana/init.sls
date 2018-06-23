{% from "grafana/map.jinja" import grafana with context %}
{% from "_macros/dev_tool.macros.jinja" import repo_pkg_service with context %}


include:
  - pkgs


{{ repo_pkg_service('grafana', grafana) }}
