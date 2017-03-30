{% from "erlang/map.jinja" import erlang with context %}

erlang:
{% if grains['os'] != 'Windows' %}
  pkgrepo.managed:
    - names: {{ erlang.repo_entries }}
    - file: {{ erlang.file }}
    - key_url: {{ erlang.key_url }}
    - refresh_db: True
    - require_in:
      - file: {{ erlang.apt_preferences_file }}
  file.managed:
    - name: {{ erlang.apt_preferences_file }}
    - content: {{ erlang.apt_preferences }}
    - require_in:
      - pkg: {{ erlang.pkg_name }}
{% endif %}
  pkg.latest:
    - name: {{ erlang.pkg_name }}
    - refresh: True
