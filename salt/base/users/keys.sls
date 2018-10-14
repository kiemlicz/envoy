#!py

def run():
  config = {}

  for username, user in __pillar__['pillar.get']("users", {}).items()
    if 'sec' in user and 'ssh' in user['sec']:
      key_spec = user['sec']['ssh']
      pillar_key_content_priv = '{}_sec_ssh_{}_privkey'.format(username, key_spec['name'])
      pillar_key_content_pub = '{}_sec_ssh_{}_pubkey'.format(username, key_spec['name'])

      def state(location):
        return {
          'file_ext.managed': [
            { 'name': key_spec[location] }
            { 'mode': 600 },
            { 'makedirs': True },
            { 'require': [
              { 'user': username }
            ]}
          ]
        }
# todo refactor key generation/copy logic
      if pillar_key_content_priv in __pillar__ and pillar_key_content_pub in __pillar__:
        config['{}_copy_{}_ssh_priv'] = state('privkey_location')['file_ext.managed'].append({'contents_pillar': pillar_key_content_priv})
        config['{}_copy_{}_ssh_pub'] = state('pubkey_location')['file_ext.managed'].append({'contents_pillar': pillar_key_content_pub})
      elif 'privkey' in key_spec and 'pubkey' in key_spec:
        config['{}_copy_{}_ssh_priv'] = state('privkey_location')['file_ext.managed'].append({'contents': key_spec['privkey']})
        config['{}_copy_{}_ssh_pub'] = state('pubkey_location')['file_ext.managed'].append({'contents': key_spec['pubkey']})
      elif 'privkey_source' in key_spec and 'pubkey_source' in key_spec:
        config['{}_copy_{}_ssh_priv'] = state('privkey_location')['file_ext.managed'].append({'source': key_spec['privkey_source']})
        config['{}_copy_{}_ssh_pub'] = state('pubkey_location')['file_ext.managed'].append({'source': key_spec['pubkey_source']})
      el:

  return config


{% for username, user in salt['pillar.get']("users", {}).items() if user.sec is defined %}

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
{% elif key_spec.privkey_source is defined %}
    - source: {{ key_spec.privkey_source }}
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
{% elif key_spec.pubkey_source is defined %}
    - source: {{ key_spec.pubkey_source }}
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

{% if user.sec.ssh_authorized_keys is defined  %}
{% for key_spec in user.sec.ssh_authorized_keys %}

{{ username }}_setup_ssh_authorized_keys:
  ssh_auth.present:
{% if key_spec.source is defined %}
    - source: {{ key_spec.source }}
{% elif key_spec.names is defined %}
    - names: {{ key_spec.names }}
{% else %}
    - name: {{ key_spec.name }}
{% endif %}
{% if key_spec.enc is defined %}
    - enc: {{ key_spec.enc }}
{% endif %}
{% if key_spec.config is defined %}
    - config: {{ key_spec.config }}
{% endif %}
    - user: {{ username }}

{% endfor %}
{% endif %}


{% endfor %}
