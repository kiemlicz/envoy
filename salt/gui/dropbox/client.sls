{% from "dropbox/map.jinja" import dropbox with context %}

dropbox:
{% if grains['os'] != 'Windows' %}
  pkgrepo.managed:
    - names: {{ dropbox.repo_entries }}
    - keyid: {{ dropbox.keyid }}
    - keyserver: {{ dropbox.keyserver }}
    - file: {{ dropbox.file }}
    - retry:
        until: True
        attempts: 3
        interval: 5
        splay: 5
    - require_in:
      - pkg: {{ dropbox.pkg_name }}
{% endif %}
  pkg.latest:
    - name: {{ dropbox.pkg_name }}
    - refresh: True
    - require:
      - sls: pkgs
