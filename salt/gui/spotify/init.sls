{% from "spotify/map.jinja" import spotify with context %}


include:
  - os


{% if spotify.required_pkgs_urls %}
spotify_prerequisites:
  pkg.installed:
    - sources:
{% for k, v in spotify.required_pkgs_urls.items() %}
      - {{ k }}: {{ v }}
{% endfor %}
    - require:
      - sls: os
    - require_in:
      - pkg: {{ spotify.pkg_name }}
{% endif %}

spotify:
{% if spotify.repo_entries is defined %}
  pkgrepo.managed:
    - names: {{ spotify.repo_entries|json_decode_list }}
    - file: {{ spotify.file }}
    - keyserver: {{ spotify.keyserver }}
    - keyid: {{ spotify.keyid }}
    - require_in:
      - pkg: {{ spotify.pkg_name }}
    - require:
      - sls: os
{% endif %}
  pkg.latest:
    - name: {{ spotify.pkg_name }}
    - refresh: True
    - require:
      - sls: os
