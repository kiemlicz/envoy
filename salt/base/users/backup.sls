{% for username in pillar['users'].keys() %}
{% set user = pillar['users'][username] %}

{% if user.backup is defined %}

{{ username }}_backup:
  file.managed:
    - name: {{ user.backup.script_location }}
    - source: salt://users/backup.sh
    - user: {{ username }}
    - template: jinja
    - makedirs: True
    - mode: 775
    - defaults:
        remote: {{ user.backup.remote }}
        locations: {{ user.backup.source_locations|join(' ') }}
        destination: {{ user.backup.destination_location }}
        archive: {{ user.backup.archive_location }}
    - require:
      - user: {{ username }}
  cron.present:
    - name: {{ user.backup.script_location }}
    - user: {{ username }}
    - hour: {{ user.backup.hour }}
    - minute: {{ user.backup.minute }}
    - require:
      - file: {{ user.backup.script_location }}

{% endif %}

{% endfor %}
