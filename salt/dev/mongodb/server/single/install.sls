{% from "mongodb/server/single/map.jinja" import mongodb with context %}


#mongodb client is installed without adding mongodb repo - thus causes conflicts with official mongo repo
exclude:
  - id: mongodb_client

mongodb:
{% if mongodb.repo_entries is defined or mongodb.repo_id is defined %}
  pkgrepo.managed:
{% if mongodb.repo_entries is defined %}
    - names: {{ mongodb.repo_entries }}
    - file: {{ mongodb.file }}
    - keyid: {{ mongodb.keyid }}
    - keyserver: {{ mongodb.keyserver }}
{% else %}
    - name: {{ mongodb.repo_id }}
    - baseurl: {{ mongodb.baseurl }}
    - humanname: {{ mongodb.repo_id }}
    - gpgcheck: 1
    - gpgkey: {{ mongodb.gpgkey }}
{% endif %}
    - require:
      - pkg: os_packages
    - require_in:
      - pkg: {{ mongodb.pkg_name }}
{% endif %}
  pkg.latest:
    - name: {{ mongodb.pkg_name }}
    - refresh: True
    - require:
      - pkg: os_packages
