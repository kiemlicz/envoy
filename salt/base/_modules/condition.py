def pillar_eq(key_1, key_2):
    return __salt__['pillar.get'](key_1) == __salt__['pillar.get'](key_2)
