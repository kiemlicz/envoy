{% from "kubernetes/master/map.jinja" import kubernetes with context %}
{% from "kubernetes/network/map.jinja" import kubernetes as kubernetes_network with context %}
{% from "_common/repo.jinja" import repository, preferences with context %}


{{ repository("kube_repository", kubernetes) }}
kubeadm:
  pkg.latest:
    - pkgs: {{ kubernetes.pkgs }}
    - refresh: True
    - require:
      - pkgrepo_ext: kube_repository
      - service: docker
  cmd.run:
    - name: kubeadm init --pod-network-cidr {{ kubernetes_network.network.cidr }}
    - require:
      - pkg: kubeadm
    - require_in:
      - sls: kubernetes.network
{% if not kubernetes.master.isolate %}
allow_schedule_on_master:
  cmd.run:
    - name: KUBECONFIG={{ kubernetes.master.kubeconfig }} kubectl taint nodes --all node-role.kubernetes.io/master-
    - require:
        - cmd: kubeadm
{% endif %}

#fixme the cmd.run must be actually a stateful command
#todo upload kubernetes config or already have the template on master
