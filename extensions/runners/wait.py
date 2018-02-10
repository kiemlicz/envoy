import logging

import salt.cache
import salt.client
import salt.syspaths as syspaths

log = logging.getLogger(__name__)


def until(expected_minions_list, action_type, data, sls=None):
    """
    Checks if all `expected_minions_list` have completed their jobs
    If so propagates event with tag: salt/$action_type/ret

    :param expected_minions_list: minion ids list that must complete jobs
    :param action_type: arbitrary string to distinguish multiple checks
    :param data: full event data
    :param sls: state.sls (string) name to wait for
    :return:
    """

    triggering_minion = data['id']
    triggering_sls = next((e for e in data['fun_args'] if isinstance(e, str)), None)  # state.highstate will receive None here

    if triggering_sls == sls:
        bank = "{}_finished".format(action_type) if sls is None else "{}_{}_finished".format(action_type, sls)
        cache = salt.cache.Cache(__opts__, syspaths.CACHE_DIR)
        cache.store(bank, triggering_minion, sls)
        finished_minions_list = cache.list(bank)  # last execution must see all stamps

        log.debug("Triggering minion: {}, completed minions: {}, expected: {}"
                  .format(triggering_minion, finished_minions_list, expected_minions_list))

        if len(finished_minions_list) == len(expected_minions_list) and \
                sorted(finished_minions_list) == sorted(expected_minions_list):
            cache.flush(bank)
            __salt__['event.send']('salt/{}/ret'.format(action_type), {
                'minions': expected_minions_list,
                'action_type': action_type,
            })
