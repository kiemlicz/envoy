#!py


def run():
  states = {}

  states['refresh_pillar'] = {
    'salt.function': [
      { 'name': "saltutil.pillar_refresh" },
      { 'tgt': "*" },
    ]
  }

  states['cluster_met'] = {
    'salt.state': [
      { 'tgt_type': "pillar" },
      { 'tgt': "redis:coordinator:True" },
      { 'sls': [
        "redis.server._orchestrate.met"
      ]},
      { 'queue': True },
      { 'saltenv': saltenv },
      { 'require': [
        { 'salt': "refresh_pillar" }
      ]}
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
