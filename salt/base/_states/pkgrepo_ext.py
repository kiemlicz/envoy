def managed(name, **kwargs):
    '''
    Removes previously configured repo
    This way state can be fully retried (otherwise pkgrepo may fallback to already broken cached data).
    It is helpful for configuring repos that often return broken key data
    '''
    if kwargs.get('keyid', False):
        __states__['pkgrepo.absent'](name, **kwargs)
    return __states__['pkgrepo.managed'](name, **kwargs)
