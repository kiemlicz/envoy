{% from "kubernetes/minikube/map.jinja" import kubernetes with context %}


minikube_update_context:
  cmd.run:
  - name: "minikube update-context"
  - runas: {{ kubernetes.minikube.user }}
  - require:
      - sls: kubernetes.minikube.{{ kubernetes.minikube.driver }}
