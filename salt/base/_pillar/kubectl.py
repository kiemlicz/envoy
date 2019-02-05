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
        # don't specify namespace if none provided, local one will be used
        q = "kubectl" if 'namespace' not in query_conf else "kubectl -n {}".format(query_conf['namespace'])
        kind = query_conf['kind']
        q = " ".join([q, "get {}".format(kind)])
        if 'name' in query_conf:
            name = query_conf['name']
            q = " ".join([q, name])
        if 'selector' in query_conf:
            selector = query_conf['selector']
            q = " ".join([q, "-l {}".format(selector)])
        else:
            raise CommandExecutionError('Cannot perform kubectl (ext_pillar), no name or selector provided')
        q = " ".join([q, "-o yaml"])
        return q

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
