{% from "atom/map.jinja" import atom with context %}
{% from "_macros/dev_tool.macros.jinja" import repo_pkg with context %}


include:
  - os


{{ repo_pkg('atom', atom) }}
