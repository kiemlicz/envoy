{% from "owncloud/map.jinja" import owncloud with context %}

owncloud:
{% if grains['os'] != 'Windows' %}
  pkgrepo.managed:
    - names: {{ owncloud.repo_entries }}
    - file: {{ owncloud.file }}
    - key_url: {{ owncloud.key_url }}
    - refresh_db: True
    - require:
      - pkg: os_packages
    - require_in:
      - pkg: {{ owncloud.client.pkg_name }}
{% endif %}
  pkg.latest:
    - name: {{ owncloud.client.pkg_name }}
    - refresh: True

#further config via dotfiles