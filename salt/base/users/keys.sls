{% for username in pillar['users'].keys() %}
{% set user = pillar['users'][username] %}

{# either generates or copies key under given locations #}

{% for key_spec in user.sec.ssh %}

{% set ssh_priv = '{}_sec_ssh_{}_privkey'.format(username, key_spec.name) %}
{% set ssh_pub = '{}_sec_ssh_{}_pubkey'.format(username, key_spec.name) %}

{% if (pillar[ssh_priv] is defined and pillar[ssh_pub] is defined) or
 (key_spec.privkey is defined and key_spec.pubkey is defined) %}
{{ username }}_copy_{{ key_spec.name }}_ssh_priv:
  file_ext.managed:
    - name: {{ key_spec.privkey_location }}
{% if pillar[ssh_priv] is defined %}
    - contents_pillar: {{ ssh_priv }}
{% elif key_spec.source is defined %}
    - source: {{ key_spec.source }}
{% else %}
    - contents: {{ key_spec.privkey | yaml_encode }}
{% endif %}
    - user: {{ username }}
    - mode: 600
    - makedirs: True
    - require:
      - user: {{ username }}
{{ username }}_copy_{{ key_spec.name }}_ssh_pub:
  file_ext.managed:
    - name: {{ key_spec.pubkey_location }}
{% if pillar[ssh_pub] is defined %}
    - contents_pillar: {{ ssh_pub }}
{% else %}
    - contents: {{ key_spec.pubkey | yaml_encode }}
{% endif %}
    - user: {{ username }}
    - mode: 644
    - makedirs: True
    - require:
      - user: {{ username }}

{% else %}

{% if key_spec.override or not salt['file.file_exists'](key_spec.privkey_location) %}
{{ username }}_generate_{{ key_spec.name }}_ssh_keys:
  file.absent:
    - names:
      - {{ key_spec.privkey_location }}
      - {{ key_spec.pubkey_location }}
  cmd.run:
    - name: /usr/bin/ssh-keygen -q -t rsa -f {{ key_spec.privkey_location }} -N ''
    - runas: {{ username }}
    - require:
      - user: {{ username }}
{% else %}
{{ username }}_cannot_generate_{{ key_spec.name }}_ssh_keys:
  test.show_notification:
    - name: Cannot generate keypair
    - text: "Cannot generate keypair as already exists"
{% endif %}

{% endif %}

{% endfor %}


{% endfor %}
