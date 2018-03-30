{% from "spotify/map.jinja" import spotify with context %}


include:
  - pkgs


{% if spotify.required_pkgs_urls %}
spotify_prerequisites:
  pkg.installed:
    - sources:
{% for k, v in spotify.required_pkgs_urls.items() %}
      - {{ k }}: {{ v }}
{% endfor %}
    - require:
      - sls: pkgs
    - require_in:
      - pkg: {{ spotify.pkg_name }}
{% endif %}

spotify:
{% if spotify.repo_entries is defined %}
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
