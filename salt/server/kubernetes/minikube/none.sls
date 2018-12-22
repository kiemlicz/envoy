minikube_driver:
  cmd.run:
  - name: "minikube start --vm-driver=" ~ {{ kubernetes.minikube.driver }}
  - require:
    - file: minikube
