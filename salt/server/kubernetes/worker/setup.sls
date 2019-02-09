{% from "kubernetes/worker/map.jinja" import kubernetes with context %}
{% from "kubernetes/network/map.jinja" import kubernetes as kubernetes_network with context %}

#load modules ip_vs, ip_vs_rr, ip_vs_wrr, ip_vs_sh, nf_conntrack_ipv4

{% set tokens = salt['mine.get']("kubernetes:master:True", "kubernetes_token", tgt_type="grain") %}
{% set ips = salt['mine.get']("kubernetes:master:True", "kubernetes_master_ip", tgt_type="grain") %}
{% set hashes = salt['mine.get']("kubernetes:master:True", "kubernetes_hash", tgt_type="grain") %}
{% set main_master_id = ips.keys()|sort|first %}


join_master:
    cmd.run:
    - name: "kubeadm join --token {{ tokens[main_master_id] }} {{ ips[main_master_id] }}:{{ kubernetes_network.nodes.port }} --discovery-token-ca-cert-hash sha256:{{ hashes[main_master_id] }}"
    - require:
        pkg: kubeadm
