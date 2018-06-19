{% from "hosts/map.jinja" import hosts with context %}


{% for address, aliases in hosts.items() %}
{{ address }}_host:
  host.present:
    - ip: {{ address }}
    - names: {{ aliases }}
{% endfor %}

{% if not hosts.items() %}
{# mandatory, otherwise require: empty sls will fail #}
hosts-notification:
  test.show_notification:
    - name: No hosts to configure
    - text: "No hosts entries configured as none specified"
{% endif %}
