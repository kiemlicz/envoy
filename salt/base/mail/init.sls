{% from "mail/map.jinja" import mail with context %}


include:
  - pkgs


mail:
  pkg.latest:
    - name: mail_pacakges
    - pkgs: {{ mail.pkgs }}
{% for config in mail.configs %}
  file_ext.managed:
    - name: {{ config.location }}
    - source: {{ config.source }}
    - makedirs: True
    - template: jinja
    - user: {{ config.user }}
    - group: {{ config.group }}
    - mode: {{ config.mode }}
    - context:
      settings: {{ config.settings }}
    - require:
      - pkg: mail_pacakges
      - pkg: os_packages
    - watch_in:
      - service: {{ mail.service }}
{% endfor %}
  service.running:
    - name: {{ mail.service }}
    - enable: True
