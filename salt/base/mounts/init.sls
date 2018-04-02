{% from "mounts/map.jinja" import mounts with context %}


{% for mount in mounts %}
{{ mount.dev }}_mount:
  mount.mounted:
    - name: {{ mount.target }}
    - device: {{ mount.dev }}
    - fstype: {{ mount.file_type }}
    - opts: {{ mount.options }}
    - mkmnt: True
    - persist: True
{% endfor %}

{% if not mounts %}
{# mandatory, otherwise require: empty sls will fail #}
mounts-notification:
  test.show_notification:
    - name: No mounts
    - text: "No mount points configured as none specified"
{% endif %}
