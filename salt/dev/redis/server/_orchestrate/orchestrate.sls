#!py


def run():
  state = {}

  if 'reset' in pillar['redis'] and pillar['redis']['reset']:
    state['redis_cluster_reset'] = {
      'salt.state': [
        { 'tgt': "*" },
        { 'sls': [
            "redis.server._orchestrate.reset"
        ]},
        { 'queue': True },
        { 'saltenv': saltenv },
        { 'pillar': pillar },
        { 'require': [
          {'salt': "refresh_pillar" }
        ]},
        { 'require_in': [
          {'salt': "redis_cluster_meet" }
        ]}
      ]
    }

  state['redis_cluster_meet'] = {
    'salt.state': [
      { 'tgt': "*" },
      { 'subset': 1 },
      { 'sls': [
        "redis.server._orchestrate.meet"
      ]},
      { 'queue': True },
      { 'saltenv': saltenv },
      { 'pillar': pillar },
      { 'require': [
        { 'salt': "refresh_pillar" }
      ]},
    ]
  }

  state['redis_cluster_slots'] = {
    'salt.state': [
      { 'tgt': "*" },
      { 'subset': 1 },
      { 'sls': [
        "redis.server._orchestrate.slots",
      ]},
      { 'queue': True },
      { 'saltenv': saltenv },
      { 'pillar': pillar },
      { 'require': [
        {'salt': "redis_cluster_meet" }
      ]}
    ]
  }

  state['redis_cluster_replicate'] = {
    'salt.state': [
      { 'tgt': "*" },
      { 'subset': 1 },
      { 'sls': [
        "redis.server._orchestrate.replicate"
      ]},
      { 'queue': True },
      { 'saltenv': saltenv },
      { 'pillar': pillar },
      { 'require': [
        {'salt': "redis_cluster_slots" }
      ]}
    ]
  }

  return state
