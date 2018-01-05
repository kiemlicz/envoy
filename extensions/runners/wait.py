import logging

import salt.cache
import salt.client
import salt.syspaths as syspaths

log = logging.getLogger(__name__)


def until(triggering_minion, expected_minions_list, action_type):
    '''
    Checks if all `expected_minions_list` have completed their jobs
    If so propagates event with tag: salt/$action_type/ret

    :param triggering_minion: minion id that caused execution of this runner
    :param expected_minions_list: minion ids list that must complete jobs
    :param action_type: arbitrary string to distinguish multiple checks
    :return:
    '''
    bank = "{}_finished".format(action_type)
    cache = salt.cache.Cache(__opts__, syspaths.CACHE_DIR)
    cache.store(bank, triggering_minion, "ok")
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
