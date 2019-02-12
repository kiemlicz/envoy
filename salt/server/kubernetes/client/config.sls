{% from "kubernetes/client/map.jinja" import kubernetes with context %}


# execute on minion containing all of the kubeconfig data
{% for location in kubernetes.config.locations %}
kubeconfig_{{ location }}:
  file.managed:
    - name: {{ location }}
    - source: salt://kubernetes/client/kubeconfig.yaml
    - makedirs: True
    - template: jinja
    - context:
        kubeconfig: {{ kubernetes.kubeconfig }}
