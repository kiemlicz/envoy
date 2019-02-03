{% from "kubernetes/master/map.jinja" import kubernetes with context %}
{% from "kubernetes/network/map.jinja" import kubernetes as kubernetes_network with context %}


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
      - sls: kubernetes.network.{{ kubernetes_network.network.provider }}
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
# todo else -> taint the node
{% endif %}

{% if kubernetes.master.upload_config %}
#todo somehow this file is unavailable on master
kubernetes_upload_config:
  module.run:
    - cp.push:
      - path: {{ kubernetes.config.locations|first }}
    - require:
      - cmd: kubeadm_init
{% endif %}

#todo mine token, hash, port and address (ip() macro will have troubles as there are two: 10.244.0.0 and 0.1 addresses)

propagate_token:
  module.run:
    - mine.send:
        - kubeadm_token
        - mine_function: cmd.run
        - args: "kubeadm token list | awk '{if(NR==2) print $1}'"
        - kwargs:
            python_shell: True
    - require:
      - cmd: kubeadm_init

propagate_hash:
  module.run:
    - mine.send:
        - kubeadm_hash
        - mine_function: cmd.run
        - args: "openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'"
        - kwargs:
            python_shell: True
    - require:
      - cmd: kubeadm_init

#todo the cmd.run should be wrapped with script and return stateful data
