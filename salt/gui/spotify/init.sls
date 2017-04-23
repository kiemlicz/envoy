{% from "spotify/map.jinja" import spotify with context %}

include:
  - pkgs

{% if spotify.required_pkgs_urls %}
spotify_prerequisite_{{ req }}:
  pkg.installed:
    - sources: {{ spotify.required_pkgs_urls }}
    - require:
     - sls: pkgs
{% if grains['os'] != 'Windows' %}
    - require_in:
     - pkg: {{ spotify.pkg_name }}
{% endif %}
{% endif %}

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
