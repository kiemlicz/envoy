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
