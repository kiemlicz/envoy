{% from "kubernetes/network/map.jinja" import kubernetes with context %}


kubernetes_network:
  sysctl.present:
    - name: "net.bridge.bridge-nf-call-iptables"
    - value: 1
  cmd.run:
    - name: kubectl apply -f {{ kubernetes.network.source }}
    - env:
        - KUBECONFIG: {{ kubernetes.config.locations|join(':') }}
    - require:
        - sysctl: kubernetes_network
