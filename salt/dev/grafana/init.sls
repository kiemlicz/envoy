{% from "grafana/map.jinja" import grafana with context %}


include:
  - pkgs


grafana:
{% if grafana.repo_entries is defined or grafana.repo_id is defined %}
  pkgrepo.managed:
{% if grafana.repo_entries is defined %}
    - names: {{ grafana.repo_entries|json_decode_list }}
    - file: {{ grafana.file }}
    - key_url: {{ grafana.key_url }}
{% else %}
    - name: {{ grafana.repo_id }}
    - baseurl: {{ grafana.baseurl }}
    - humanname: {{ grafana.repo_id }}
    - gpgcheck: 1
    - gpgkey: {{ grafana.gpgkey }}
{% endif %}
    - require:
      - pkg: os_packages
    - require_in:
      - pkg: {{ grafana.pkg_name }}
{% endif %}
  pkg.latest:
    - name: {{ grafana.pkg_name }}
    - refresh: True
    - require:
      - pkg: os_packages
  service.running:
    - name: {{ grafana.service_name }}
    - enable: True
    - require:
      - pkg: {{ grafana.pkg_name }}
