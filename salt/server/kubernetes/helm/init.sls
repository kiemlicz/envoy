{% from "kubernetes/helm/map.jinja" import helm with context %}

helm:
  cmd.script:
    - name: {{ helm.installer_url }}
    - env: {{ helm.options }}
