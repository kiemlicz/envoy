{% from "erlang/map.jinja" import erlang with context %}
{% from "_common/util.jinja" import retry with context %}
{% from "_common/repo.jinja" import repository with context %}


include:
  - os


{% set erlang_repo_id = erlang.file ~ "_" ~ repo.names|first ~ "_repository" %}

{{ repository(erlang_repo_id, erlang, True) }}
    - require:
      - sls: os
{% if erlang.names is defined %}
{{ preferences(erlang.file ~ "_" ~ repo.names|first ~ "_preferences", erlang, erlang.apt_preferences_file) }}
    - require:
      - pkgrepo_ext: {{ erlang_repo_id }}
    - require_in:
        - pkg: {{ erlang.pkg_name }}
{% endif %}
erlang:
  pkg.latest:
    - name: {{ erlang.pkg_name }}
    - refresh: True
    - require:
      - pkgrepo_ext: {{ erlang_repo_id }}
