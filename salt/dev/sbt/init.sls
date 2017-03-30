{% from "sbt/map.jinja" import sbt with context %}
{% from "_macros/dev_tool.macros.jinja" import add_environmental_variable,add_to_path with context %}

sbt:
{% if grains['os'] != 'Windows' %}
  pkgrepo.managed:
    - names: {{ sbt.repo_entries }}
    - file: {{ sbt.file }}
    - keyid: {{ sbt.keyid }}
    - keyserver: {{ sbt.keyserver }}
    - require_in:
      - pkg: {{ sbt.pkg_name }}
{% endif %}
  pkg.latest:
    - name: {{ sbt.pkg_name }}
    - refresh: True
{{ add_environmental_variable(sbt.environ_variable, sbt.generic_link, sbt.exports_file) }}
{{ add_to_path(sbt.environ_variable, sbt.path_inside, sbt.exports_file) }}

# todo on windows need to find the dir
