{% set entries = pillar.get('mounts', []) %}
{% if entries %}
{% for mount in entries %}
{{ mount.dev }}_mount:
  mount.mounted:
    - name: {{ mount.target }}
    - device: {{ mount.dev }}
    - fstype: {{ mount.file_type }}
    - opts: {{ mount.options }}
    - persist: True
{% endfor %}
{% else %}
empty-mount-notification:
  test.show_notification:
    - name: None mounted
    - text: "Nothing was mounted as nothing was specified"
{% endif %}
