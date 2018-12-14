#!py


def run():
  states = {}

  states['refresh_pillar'] = {
    'salt.function': [
      { 'name': "saltutil.pillar_refresh" },
      { 'tgt': pillar['redis']['coordinator'] },
    ]
  }

  states['cluster_met'] = {
    'salt.state': [
      { 'tgt': pillar['redis']['coordinator'] },
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
      { 'tgt': pillar['redis']['coordinator'] },
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
