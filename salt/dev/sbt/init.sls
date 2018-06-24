{% from "sbt/map.jinja" import sbt with context %}
{% from "_macros/dev_tool.macros.jinja" import add_environmental_variable,add_to_path with context %}


include:
  - os
  - users


sbt:
{% if sbt.repo_entries is defined or sbt.repo_id is defined %}
  pkgrepo.managed:
{% if sbt.repo_entries is defined %}
    - names: {{ sbt.repo_entries|json_decode_list }}
    - file: {{ sbt.file }}
    - keyid: {{ sbt.keyid }}
    - keyserver: {{ sbt.keyserver }}
{% else %}
    - name: {{ sbt.repo_id }}
    - baseurl: {{ sbt.baseurl }}
    - humanname: {{ sbt.repo_id }}
    - gpgcheck: 0
{% endif %}
    - require:
      - sls: os
    - require_in:
      - pkg: {{ sbt.pkg_name }}
{% endif %}
  pkg.latest:
    - name: {{ sbt.pkg_name }}
    - refresh: True
    - require:
      - sls: users
{{ add_environmental_variable(sbt.environ_variable, sbt.generic_link, sbt.exports_file) }}
{{ add_to_path(sbt.environ_variable, sbt.path_inside, sbt.exports_file) }}

# todo on windows need to find the dir
