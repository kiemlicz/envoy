{% for address, aliases in pillar.get('hosts', {}).items() %}
{{ address }}_host:
  host.present:
    - ip: {{ address }}
    - names: {{ aliases }}
{% endfor %}

{% if not pillar.get('hosts', []) %}
empty-hosts-notification:
  test.show_notification:
    - name: No hosts present
    - text: "No hosts configured as none specified"
{% endif %}
