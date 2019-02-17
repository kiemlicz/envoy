{% from "kubernetes/minikube/map.jinja" import kubernetes with context %}


minikube_driver:
  cmd.run:
  - name: "minikube start --vm-driver=none"
  - runas: {{ kubernetes.user }}
  - require:
    - file: minikube
