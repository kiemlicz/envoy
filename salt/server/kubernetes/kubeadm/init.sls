{% from "kubernetes/kubeadm/map.jinja" import kubeadm with context %}
{% from "_common/repo.jinja" import repository, preferences with context %}

{{ repository("kubeadm_repository", kubeadm, require=[], require_in=[{'pkg': kubeadm.pkgs}]) }}
kubeadm:
  pkg.latest:
    - name:
    - pkgs: {{ kubeadm.pkgs }}
    - refresh: True
    - require:
      - sls: os
