{% from "kubernetes/map.jinja" import kubernetes with context %}
{% from "_common/util.jinja" import retry with context %}


include:
  - os
  - kvm
  - minikube


kubernetes:
{% if kubernetes.names is defined or kubernetes.repo_id is defined %}
  pkgrepo.managed:
    - names: {{ kubernetes.names|json_decode_list }}
    - file: {{ kubernetes.file }}
    - key_url: {{ kubernetes.key_url }}
{{ retry()| indent(4) }}
    - require:
      - sls: os
    - require_in:
      - pkg: {{ kubernetes.client.pkg_name }}
{% endif %}
  pkg.latest:
    - name: {{ kubernetes.client.pkg_name }}
    - refresh: True

#further config via dotfiles