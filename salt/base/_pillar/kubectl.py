import logging

import salt.utils.yaml

log = logging.getLogger(__name__)

__virtualname__ = 'kubectl'


def __virtual__():
    return True


def ext_pillar(minion_id, pillar, *args, **kwargs):
    def merge(input_dict, output_dict):
        for e in input_dict:
            output_dict = salt.utils.dictupdate.merge(
                output_dict,
                e,
                strategy='smart',
                merge_lists=True
            )
        return output_dict

    ret = {}
    config_path = kwargs['config']
    queries = kwargs['queries']
    for query_conf in queries:
        command = "kubectl get {} {} -o yaml".format(query_conf['type'], query_conf['name'])
        output = __salt__['cmd.run_stdout'](command, python_shell=True, env={'KUBECONFIG': config_path})
        data = {query_conf['key']: salt.utils.yaml.safe_load(output)}
        merge(data, ret)

    return ret
