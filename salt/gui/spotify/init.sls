{% from "spotify/map.jinja" import spotify with context %}

include:
  - pkgs

spotify:
{% if grains['os'] != 'Windows' %}
  pkgrepo.managed:
    - names: {{ spotify.repo_entries }}
    - file: {{ spotify.file }}
    - keyserver: {{ spotify.keyserver }}
    - keyid: {{ spotify.keyid }}
    - refresh_db: True
    - require_in:
      - pkg: {{ spotify.pkg_name }}
{% endif %}
  pkg.latest:
    - name: {{ spotify.pkg_name }}
    - refresh: True
    - require:
      - sls: pkgs
