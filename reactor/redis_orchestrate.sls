{% if data['fun'] == 'state.highstate' and data['success']|to_bool %}

{% set jobs = salt['saltutil.runner']("jobs.list_jobs").items()|map(attribute=1)|selectattr("Function", "equalto", "state.highstate")|list %}

{% set completed_minions = jobs|map(attribute='Target')|unique %}
{% set masters = salt['pillar.get']("redis.master_bind_list")|map(attribute="host_id")|list %}
{% set slaves = salt['pillar.get']("redis.slave_bind_list")|map(attribute="host_id")|list %}
{% set expected_minions = masters + slaves %}

{% if completed_minions|compare_lists(expected_minions)|length == 0 %}

redis_orchestrate:
  runner.state.orchestrate:
    - tgt: {{ completed_minions }}
    - args:
      - mods: _orchestrate.redis.server.cluster.orch
      - saltenv: {{ saltenv }}}
      - pillar:
          redis_minions: {{ completed_minions }}

{% endif %}
{% endif %}
