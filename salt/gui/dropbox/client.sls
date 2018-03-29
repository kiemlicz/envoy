{% from "dropbox/map.jinja" import dropbox with context %}
{% from "_common/util.jinja" import retry with context %}

dropbox:
{% if grains['os'] != 'Windows' %}
  pkgrepo.managed:
    - names: {{ dropbox.repo_entries }}
    - keyid: {{ dropbox.keyid }}
    - keyserver: {{ dropbox.keyserver }}
    - file: {{ dropbox.file }}
{{ retry()| indent(4) }}
    - require_in:
      - pkg: {{ dropbox.pkg_name }}
{% endif %}
  pkg.latest:
    - name: {{ dropbox.pkg_name }}
    - refresh: True
    - require:
      - sls: pkgs
