{% from "sbt/map.jinja" import sbt with context %}
{% from "_macros/dev_tool.macros.jinja" import add_environmental_variable,add_to_path with context %}
{% from "_common/repo.jinja" import repository with context %}


include:
  - os
  - users


{% set sbt_repo_id = "sbt_repository" %}
{{ repository(sbt_repo_id, sbt, enabled=(sbt.names is defined or sbt.repo_id is defined),
     require=[{'sls': "os"}], require_in=[{'pkg': sbt.pkg_name}]) }}
sbt:
  pkg.latest:
    - name: {{ sbt.pkg_name }}
    - refresh: True
    - require:
      - sls: users
{{ add_environmental_variable(sbt.environ_variable, sbt.generic_link, sbt.exports_file) }}
{{ add_to_path(sbt.environ_variable, sbt.path_inside, sbt.exports_file) }}

# todo on windows need to find the dir
