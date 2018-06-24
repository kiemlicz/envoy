{% from "os/hosts/map.jinja" import hosts with context %}


{% for address, aliases in hosts.items() %}
{{ address }}_host:
  host.present:
    - ip: {{ address }}
    - names: {{ aliases }}
{% endfor %}
