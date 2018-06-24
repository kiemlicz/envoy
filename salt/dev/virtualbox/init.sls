{% from "virtualbox/map.jinja" import virtualbox with context %}


include:
  - os


virtualbox:
{% if virtualbox.repo_entries is defined or virtualbox.repo_id is defined %}
  pkgrepo.managed:
{% if virtualbox.repo_entries is defined %}
    - names: {{ virtualbox.repo_entries|json_decode_list }}
    - file: {{ virtualbox.file }}
    - key_url: {{ virtualbox.key_url }}
{% else %}
    - name: {{ virtualbox.repo_id }}
    - baseurl: {{ virtualbox.baseurl }}
    - humanname: {{ virtualbox.repo_id }}
    - gpgcheck: 1
    - gpgkey: {{ virtualbox.gpgkey }}
{% endif %}
    - require:
      - sls: os
    - require_in:
      - pkg: {{ virtualbox.pkg_name }}
{% endif %}
  pkg.latest:
    - name: {{ virtualbox.pkg_name }}
    - refresh: True
    - require:
      - sls: os
