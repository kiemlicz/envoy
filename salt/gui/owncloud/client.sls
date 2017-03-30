{% from "owncloud/map.jinja" import owncloud with context %}

include:
  - pkgs

owncloud:
{% if grains['os'] != 'Windows' %}
  pkgrepo.managed:
    - names: {{ owncloud.repo_entries }}
    - file: {{ owncloud.file }}
    - key_url: {{ owncloud.key_url }}
    - refresh_db: True
{% endif %}
  pkg.latest:
    - name: {{ owncloud.client.pkg_name }}
    - refresh: True
    - require:
      - sls: pkgs

#further config via dotfiles