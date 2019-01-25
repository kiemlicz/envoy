import logging

import salt.utils.yaml
from salt.defaults import DEFAULT_TARGET_DELIM
from salt.exceptions import CommandExecutionError

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

    def query(query_conf):
        kind = query_conf['kind']
        namespace = query_conf['namespace'] if 'namespace' in query_conf else 'default'
        if 'name' in query_conf:
            name = query_conf['name']
            return "kubectl get {} {} -o yaml -n {}".format(kind, name, namespace)
        if 'selector' in query_conf:
            selector = query_conf['selector']
            return "kubectl get {} -o yaml -l {} -n {} ".format(kind, selector, namespace)
        else:
            raise CommandExecutionError('Cannot perform kubectl (ext_pillar), no name or selector provided')

    env = {'KUBECONFIG': kwargs['config']} if 'config' in kwargs else None
    queries = kwargs['queries']
    for query_conf in queries:
        command = query(query_conf)
        output = __salt__['cmd.run_stdout'](command, python_shell=True, env=env)
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
