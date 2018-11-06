#!py


def run():
  states = {}

  # fixme queue the orchestration runs

  states['redis_cluster_met'] = {
    'salt.state': [
      { 'tgt': "redis:coordinator:True" },
      { 'tgt_type': "pillar" },
      { 'sls': [
        "redis.server._orchestrate.met"
      ]},
      { 'saltenv': saltenv },
      { 'pillar': pillar },
      { 'require': [
        { 'salt': "refresh_pillar" }
      ]},
    ]
  }


  if 'reset' in pillar['redis'] and pillar['redis']['reset']:
    states['redis_cluster_reset'] = {
      'salt.state': [
        { 'tgt': "*" },
        { 'sls': [
            "redis.server._orchestrate.reset"
        ]},
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

  states['redis_cluster_meet'] = {
    'salt.state': [
      { 'tgt': "*" },
      { 'subset': 1 },
      { 'sls': [
        "redis.server._orchestrate.meet"
      ]},
      { 'saltenv': saltenv },
      { 'pillar': pillar },
      { 'require': [
        { 'salt': "refresh_pillar" }
      ]},
    ]
  }

  states['redis_cluster_slots'] = {
    'salt.state': [
      { 'tgt': "*" },
      { 'subset': 1 },
      { 'sls': [
        "redis.server._orchestrate.slots",
      ]},
      { 'saltenv': saltenv },
      { 'pillar': pillar },
      { 'require': [
        {'salt': "redis_cluster_meet" }
      ]}
    ]
  }

  states['redis_cluster_replicate'] = {
    'salt.state': [
      { 'tgt': "*" },
      { 'subset': 1 },
      { 'sls': [
        "redis.server._orchestrate.replicate"
      ]},
      { 'saltenv': saltenv },
      { 'pillar': pillar },
      { 'require': [
        {'salt': "redis_cluster_slots" }
      ]}
    ]
  }

  return states
