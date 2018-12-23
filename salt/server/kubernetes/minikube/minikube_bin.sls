{% from "kubernetes/minikube/map.jinja" import kubernetes with context %}


minikube:
  file.managed:
  - name: {{ kubernetes.minikube.location }}
  - source: {{ kubernetes.minikube.url }}
  - mode: 755
  - require:
      - service: docker
