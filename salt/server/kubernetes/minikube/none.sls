minikube_driver:
  cmd.run:
  - name: "minikube start --vm-driver=none"
  - require:
    - file: minikube
