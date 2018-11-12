#!py

#wait_for_all_instances:
#  salt.wait_for_event:
#    - name: salt/redis/kubernetes/*
#    - id_list:
#        - redis-cluster-0
#        - redis-cluster-1
#        - redis-cluster-2
#        - redis-cluster-3
#    - event_id:
#        - pod_name
# todo pillar.get size and create list here in jinja, this would be safe
# todo add onfail

def run():
  states = {}

  states['cluster_met'] = {
    'salt.state': [
      { 'tgt_type': "pillar" },
      { 'tgt': "redis:coordinator:True" },
      { 'sls': [
        "redis.server._orchestrate.met"
      ]},
      { 'queue': True },
      { 'saltenv': saltenv },
    ]
  }

  states['cluster_managed'] = {
    'salt.state': [
      { 'tgt': "redis:coordinator:True" },
      { 'tgt_type': "pillar" },
      { 'sls': [
        "redis.server._orchestrate.managed",
      ]},
      { 'queue': True },
      { 'saltenv': saltenv },
      { 'require': [
        {'salt': "cluster_met" }
      ]}
    ]
  }
  return states