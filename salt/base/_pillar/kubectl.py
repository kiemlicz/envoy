import logging

import salt.utils.yaml
from salt.defaults import DEFAULT_TARGET_DELIM

log = logging.getLogger(__name__)

__virtualname__ = 'kubectl'


def __virtual__():
    return True


def ext_pillar(minion_id, pillar, *args, **kwargs):
    ret = {}

    def wrap(keys, val):
        if len(keys) > 1:
            return {keys[0]: wrap(keys[1:], val)}
        elif len(keys) == 1:
            return {keys[0]: val}
        else:
            return {}

    config_path = kwargs['config']
    queries = kwargs['queries']
    for query_conf in queries:
        kind = query_conf['kind']
        name = query_conf['name']
        namespace = query_conf['namespace'] if 'namespace' in query_conf else 'default'
        command = "kubectl get {} {} -o yaml -n {}".format(kind, name, namespace)
        output = __salt__['cmd.run_stdout'](command, python_shell=True, env={'KUBECONFIG': config_path})
        if output:
            key_list = query_conf['key'].split(DEFAULT_TARGET_DELIM)
            data = wrap(key_list, salt.utils.yaml.safe_load(output))
            ret = salt.utils.dictupdate.merge(
                ret,
                data,
                strategy='smart',
                merge_lists=True
            )
    return ret
