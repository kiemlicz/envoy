{% from "dropbox/map.jinja" import dropbox with context %}
{% from "_common/util.jinja" import retry with context %}

dropbox:
{% if dropbox.repo_entries is defined or dropbox.repo_id is defined %}
  pkgrepo.managed:
{% if dropbox.repo_entries is defined %}
    - names: {{ dropbox.repo_entries|json_decode_list }}
    - keyid: {{ dropbox.keyid }}
    - keyserver: {{ dropbox.keyserver }}
    - file: {{ dropbox.file }}
{% else %}
    - name: {{ dropbox.repo_id }}
    - baseurl: {{ dropbox.baseurl }}
    - humanname: {{ dropbox.repo_id }}
    - gpgcheck: 1
    - gpgkey: {{ dropbox.gpgkey }}
{% endif %}
{{ retry()| indent(4) }}
    - require_in:
      - pkg: {{ dropbox.pkg_name }}
{% endif %}
  pkg.latest:
    - name: {{ dropbox.pkg_name }}
    - refresh: True
    - require:
      - sls: pkgs
