{% for mount in pillar.get('mounts', []) %}
{{ mount.dev }}_mount:
  mount.mounted:
    - name: {{ mount.target }}
    - device: {{ mount.dev }}
    - fstype: {{ mount.file_type }}
    - opts: {{ mount.options }}
    - persist: True
{% endfor %}

{% if not pillar.get('mounts', []) %}
empty-mount-notification:
  test.show_notification:
    - name: None mounted
    - text: "Nothing was mounted as nothing was specified"
{% endif %}
