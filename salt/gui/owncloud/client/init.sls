{% from "owncloud/client/client.map.jinja" import owncloud with context %}

owncloud:
{% if owncloud.repo_entries %}
  pkgrepo.managed:
    - names: {{ owncloud.repo_entries }}
    - file: {{ owncloud.file }}
    - key_url: {{ owncloud.key_url }}
    - refresh_db: True
    - require:
      - pkg: os_packages
    - require_in:
      - pkg: {{ owncloud.pkg_name }}
{% endif %}
  pkg.latest:
    - name: {{ owncloud.pkg_name }}
    - refresh: True

#further config via dotfiles