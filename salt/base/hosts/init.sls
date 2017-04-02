{% set entries = pillar.get('hosts', {}) %}
{% if entries %}
{% for address, aliases in entries.items() %}
{{ address }}_host:
  host.present:
    - ip: {{ address }}
    - names: {{ aliases }}
{% endfor %}
{% else %}
empty-hosts-notification:
  test.show_notification:
    - name: No hosts present
    - text: "No hosts configured as none specified"
{% endif %}
