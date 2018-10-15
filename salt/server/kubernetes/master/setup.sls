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
{% if kubernetes.master.reset %}
kubeadm_reset:
  cmd.run:
    - name: "echo y | kubeadm reset"
    - require:
        - pkg: kubeadm
    - require_in:
        - cmd: kubeadm_init
{% endif %}
kubeadm_init:
  cmd.run:
    - name: kubeadm init --pod-network-cidr {{ kubernetes_network.network.cidr }}
    - require:
      - pkg: kubeadm
    - require_in:
      - sls: kubernetes.network
    - unless: test -f /etc/kubernetes/admin.conf
{% if not kubernetes.master.isolate %}
allow_schedule_on_master:
  cmd.script:
    - name: untaint.sh {{ grains['id'] }}
    - source: salt://kubernetes/untaint.sh
    - env:
        - KUBECONFIG: {{ kubernetes.config.locations|join(':') }}
    - require:
        - cmd: kubeadm_init
{% endif %}

#todo the cmd.run should be wrapped with script and return stateful data
#todo upload kubernetes config or already have the template on master
