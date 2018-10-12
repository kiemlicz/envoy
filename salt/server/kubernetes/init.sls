{% from "kubernetes/map.jinja" import kubernetes with context %}
{% from "_common/util.jinja" import retry with context %}


include:
  - os
  - kvm
  - kubectl
  - minikube
