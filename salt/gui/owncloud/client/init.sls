{% from "owncloud/client/map.jinja" import owncloud with context %}
{% from "_common/util.jinja" import retry with context %}


owncloud:
{% if owncloud.repo_entries is defined or owncloud.repo_id is defined %}
  pkgrepo.managed:
    - names: {{ owncloud.repo_entries|json_decode_list }}
    - file: {{ owncloud.file }}
    - key_url: {{ owncloud.key_url }}
{{ retry()| indent(4) }}
    - require:
      - pkg: os_packages
    - require_in:
      - pkg: {{ owncloud.client.pkg_name }}
{% endif %}
  pkg.latest:
    - name: {{ owncloud.client.pkg_name }}
    - refresh: True

#further config via dotfiles