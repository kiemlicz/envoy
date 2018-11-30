import logging
import time
import copy
from salt.exceptions import SaltException


log = logging.getLogger(__name__)


class RedisClusterConfigurationException(SaltException):
    pass


# todo move to utils
def _format_comments(comments):
    ret = '. '.join(comments)
    if len(comments) > 1:
        ret += '.'
    return ret


def _fail(ret, msg, comments=None):
    log.error(msg)
    ret['result'] = False
    if comments:
        msg += '\nFailure reason: '
        msg += _format_comments(comments)
    ret['comment'] = msg
    return ret


def _filter_ip(ips, cidr):
    if cidr:
        return [e for e in ips if __salt__['network.ip_in_subnet'](e, cidr)]
    else:
        return ips


def _cluster_state(instances, cidr, include_slots=True):
    '''
    Enrich input nodes map with cluster nodes and cluster slots commands
    :param instances:
    :param cidr:
    :return:
    '''
    for name, details in instances.items():
        ip = _filter_ip(details['ips'], cidr)[0]
        port = details['port']
        node_view = __salt__['redis_ext.nodes'](ip, port)
        if not node_view:
            raise RedisClusterConfigurationException("Cannot create cluster view from: {}:{}".format(ip, port))

        myself_found = False
        for ip_port, node_details in node_view.items():
            if 'fail' in node_details['flags']:
                raise RedisClusterConfigurationException("Cluster view as seen from {}:{} contains 'fail' flag for {}".format(ip, port, ip_port))
            elif 'myself' in node_details['flags']:
                myself_found = True
                details['master'] = True if 'master' in node_details['flags'] else False
                if not details['master']:
                    details['master_id'] = node_details['master_id']

        if not myself_found:
            raise RedisClusterConfigurationException("Redis instance {}:{} doesn't contain 'myself' in its cluster nodes".format(ip, port))

        if include_slots:
            details['current_slots'] = __salt__['redis_ext.slots'](ip, port)

    return instances


def _failed_instances(instances, cidr):
    failed = {}
    for name, details in instances.items():
        ip = _filter_ip(details['ips'], cidr)[0]
        port = details['port']
        node_view = __salt__['redis_ext.nodes'](ip, port)
        f = [(node_details['node_id'], True if 'master' in node_details['flags'] else False) for ip_port, node_details in node_view.items() if 'fail' in node_details['flags']]
        if f:
            failed[name] = f
    return failed


def _has_any_slots(nodes):
    for details in nodes.values():
        if details['current_slots']:
            return True
    return False


def _ip_port(instances, name, cidr):
    return _filter_ip(instances[name]['ips'], cidr)[0], instances[name]['port']


def met(name, instances, cidr=None, meet_delay=5):
    '''
    Redis CLUSTER MEETs all `instances`
    This state yields all instances connected to others (given proper network configuration etc.)
    It is the caller responsibility to pass all available `instances`
    All previously known but 'failed' instances will be removed from the cluster view.

    :param name:
    :param instances: All currently available redis instances: { 'hostname1': {'ips': ["127.0.0.1", "1.2.3.4"], 'port': 6379 }}
    :param cidr: network with mask to filter out ip addresses from 'ips' list
    :param meet_delay:
    '''
    ret = {'name': name,
           'result': False,
           'changes': {},
           'comment': ''}

    if not instances:
        log.info("No changes (cluster meet), required 'nodes' map is empty")
        ret['result'] = True
        return ret

    initiator_ip, initiator_port = _ip_port(instances, instances.keys()[0], cidr)
    others = [[_filter_ip(v['ips'], cidr)[0], v['port']] for k, v in instances.items()]

    log.info("Cluster meet from {}:{} to: {}".format(initiator_ip, initiator_port, others))

    def loop(attempts):
        if attempts <= 0:
            r = __salt__['redis_ext.meet'](initiator_ip, initiator_port, others)
            time.sleep(meet_delay)
            return r
        elif __salt__['redis_ext.meet'](initiator_ip, initiator_port, others):
            time.sleep(meet_delay)
            failed = _failed_instances(instances, cidr)
            if failed:
                log.warn("There are instances with failed flag: {}, they will be forgotten".format(failed))
                for instance, id_list in failed.items():
                    for id, is_master in id_list:
                        ip, port = _ip_port(instances, instance, cidr)
                        if is_master and not __salt__['redis_ext.reset'](ip, port, hard=False):
                            # if after meet this occurs it means that the old master is surely dead
                            # as 'cannot forget master' then the reset is performed
                            return False
                        elif not is_master and not __salt__['redis_ext.forget'](ip, port, id):
                            return False
                return loop(attempts - 1)
            else:
                return True
        else:
            return False

    if loop(1):
        try:
            _cluster_state(instances, cidr, include_slots=False)
        except RedisClusterConfigurationException as e:
            log.exception(e)
            return _fail(ret, "Cluster state is still inconsistent")
        log.debug("Cluster met successful")
        ret['result'] = True
        ret['changes']["{}:{}".format(initiator_ip, initiator_port)] = "met: {}".format(others)
        return ret
    else:
        return _fail(ret, "Unable to perform cluster meet")


def balanced(name, instances, desired_masters=None, desired_slots=None, total_slots=16384, cidr=None, policy="split"):
    '''
    For current number of masters balances the cluster

    :param name:
    :param instances:
    :param desired_masters: [{'name': 'master1'}, {'name': 'master2'}]
    :param desired_slots: {'master1': [1,2,3], 'master2': [4,5,6]}
    :param total_slots: 16384
    :param cidr:
    :param policy:
    :return:
    '''
    ret = {'name': name,
           'result': False,
           'changes': {},
           'comment': ''}

    if not instances:
        log.info("No changes (cluster balance) will be made as required 'nodes' map is empty")
        ret['result'] = True
        return ret

    nodes_ext = copy.deepcopy(instances)
    try:
        nodes_ext = _cluster_state(nodes_ext, cidr)
    except RedisClusterConfigurationException as e:
        log.exception(e)
        return _fail(ret, "Cluster balancing: cannot gather cluster-wide information")

    actions = {}

    if not desired_masters:
        log.info("Cluster balancing: using current's view masters")
        desired_masters = [{'name': m} for m, v in nodes_ext.items() if v['master']]

    if desired_slots is None:
        desired_slots = {}
        # todo add consistent hashing

        # sort desired masters lexicographically to avoid redundant migration
        desired_masters.sort(key=lambda m: m['name'])

        def split():
            '''
            Splits the slots range in consecutive, continuous ranges
            '''
            s, r = divmod(total_slots, len(desired_masters))
            start = 0
            for master in desired_masters:
                end = start + s if start + s + r < total_slots else start + s + r
                for i in range(start, end):
                    desired_slots.setdefault(master['name'], []).append(i)
                start = end
            return desired_slots

        def one_by_one():
            '''
            Splits the slots range in discontinuous sets e.g. node1: [0,2,4,6]; nodes2: [1,3,5,7]
            '''
            for i in xrange(total_slots):
                desired_slots.setdefault(desired_masters[i % len(desired_masters)]['name'], []).append(i)
            return desired_slots

        policies = {
            'split': split,
            'one_by_one': one_by_one
        }
        policies[policy]()

    for desired_master, desired_slot_list in desired_slots.items():
        add = set(desired_slot_list) - set(nodes_ext[desired_master]['current_slots'])
        migrate_map = {}
        for other_node in [e for e in nodes_ext.keys() if e != desired_master and nodes_ext[e]['master']]:
            migrate_to_desired_master = set(nodes_ext[other_node]['current_slots']) & set(add)
            if len(migrate_to_desired_master) != 0:
                migrate_map[other_node] = migrate_to_desired_master
                add = add - migrate_to_desired_master
        actions[desired_master] = {
            'add': add,
            'migrate': migrate_map
        }

    log.info("All nodes: {}, desired masters: {}".format(nodes_ext.keys(), desired_masters))
    log.debug("Cluster balancing: actions: {}".format(actions))

    for desired_master, action_map in actions.items():
        dest_ip, dest_port = _ip_port(nodes_ext, desired_master, cidr)
        changes_key = "destination node: {}".format(desired_master)

        # this is safe action, slots are not assigned anywhere else fixme relax this requirement
        # but it may happen that previous masters join again, they obviously should be wiped or should they be migrated?
        # or fail hard?! and add onfail logic?????
        # I think that fail is good option
        if __salt__['redis_ext.addslots'](dest_ip, dest_port, action_map['add']):
            log.debug("Cluster balancing: added slots to {}:{}".format(dest_ip, dest_port))
            ret['changes'][changes_key] = {
                'slots added': action_map['add']
            }
        else:
            return _fail(ret, "Cluster balancing: unable to add slots to: {}:{}".format(dest_ip, dest_port))

        for source_name, migrate_to_desired_master in action_map['migrate'].items():
            src_ip, src_port = _ip_port(nodes_ext, source_name, cidr)
            log.info("Cluster balancing: migrating slots from {}:{} to {}:{}".format(src_ip, src_port, dest_ip, dest_port))
            log.debug("Slots: {}".format(migrate_to_desired_master))
            migrate_ret = __salt__['redis_ext.migrate'](src_ip, src_port, dest_ip, dest_port, migrate_to_desired_master)
            if migrate_ret['result']:
                ret['changes'][changes_key].update({"slots migrated to this node": migrate_ret['migrated']})
            else:
                ret['changes'][changes_key].update({"slots migrated to this node": migrate_ret['migrated']})
                ret['changes'][changes_key].update({"slots that failed to migrate to this node": migrate_ret['failed']})
                return _fail(ret, "Cluster balancing: slots migration failed ({}:{} -> {}:{})".format(src_ip, src_port, dest_ip, dest_port))

    ret['result'] = True
    return ret


def replicated(name, instances, slaves_list=None, masters_list=None, replication_factor=2, cidr=None):
    '''
    CLUSTER REPLICATE either using by name slaves_list list or if the list is None, using replication_factor
    Assumes that the data will be split among all passed master nodes.
    The number of slot spaces will be equal to: `len(nodes)/replication_factor`

    :param name:
    :param instances:
    :param slaves_list: [{'name': 'name1', 'of_master': 'master2'}, {'name': 'name2', 'of_master': 'master1'}]
    :param masters_list: [{'name': 'master1'}, {'name': 'master2'}]
    :param replication_factor:
    :param cidr:
    :return:
    '''
    ret = {'name': name,
           'result': False,
           'changes': {},
           'comment': ''}

    if not instances:
        log.info("No changes (cluster replicate) will be made as required 'nodes' map is empty")
        ret['result'] = True
        return ret

    if (not slaves_list and not masters_list) and len(instances) < replication_factor:
        return _fail(ret, "Cluster replicate: insufficient number of redis instances ({}) for replication factor = {}".format(len(instances), replication_factor))

    nodes_ext = copy.deepcopy(instances)
    try:
        nodes_ext = _cluster_state(nodes_ext, cidr)
    except RedisClusterConfigurationException as e:
        log.exception(e)
        return _fail(ret, "Cluster replicate: cannot gather cluster-wide information")

    def _promote(nodes_ext, desired_masters):
        # reset roles of current slaves that must become masters
        upgrade = {}
        for current_slave in [m['name'] for m in desired_masters if not nodes_ext[m['name']]['master']]:
            upgrade[current_slave] = nodes_ext[current_slave]

        reset_ret = __states__['redis_ext.reset']("{}_reset".format(name), upgrade, cidr, hard=False)
        if not reset_ret['result']:
            return reset_ret
        # meet again, because of reset
        return __states__['redis_ext.met']("{}_meet".format(name), nodes_ext, cidr)

    if not slaves_list and not masters_list:
        all_nodes = nodes_ext.keys()
        key_spaces = len(all_nodes) / replication_factor
        current_masters = [{'name': m} for m, v in nodes_ext.items() if v['master']]
        current_slaves = [{'name': s} for s, v in nodes_ext.items() if not v['master']]

        if key_spaces > len(current_masters):
            # too many slaves
            # todo slave picking policy
            number_of_extra_slaves = key_spaces - len(current_masters)
            extra_slaves = current_slaves[-number_of_extra_slaves:]
            promote_ret = _promote(nodes_ext, extra_slaves)
            if not promote_ret['result']:
                return _fail(ret, "Cluster replicate: promotion of slaves has failed", [promote_ret['comment']])
            # replica migration will take from here
        elif key_spaces < len(current_masters):
            # too many masters
            number_of_extra_masters = len(current_masters) - key_spaces
            desired_masters = current_masters[:-number_of_extra_masters]
            extra_masters = current_masters[-number_of_extra_masters:]
            # fail or balance, lets balance
            log.info("Cluster replicate: migrating slots to: {}".format(desired_masters))
            balanced_ret = __states__['redis_ext.balanced'](name, instances, desired_masters, cidr=cidr)
            if not balanced_ret['result']:
                return _fail(ret, "Cluster replicate: unable to balance slots among: {}".format(desired_masters), [balanced_ret['comment']])
            log.info("Cluster replicate: creating slaves: {}".format(extra_masters))
            for new_slave in extra_masters:
                slave_ip, slave_port = _ip_port(nodes_ext, new_slave['name'], cidr)
                # replica migration will balance this poor choice
                master_ip, master_port = _ip_port(nodes_ext, desired_masters[0]['name'], cidr)
                if not __salt__['redis_ext.flushall'](slave_ip, slave_port):
                    return _fail(ret, "Cluster replicate: unable to flushall data from old master")
                if not __salt__['redis_ext.replicate'](master_ip, master_port, slave_ip, slave_port):
                    return _fail(ret, "Cluster replicate: slave ({}:{}) cannot replicate master ({}:{})".format(slave_ip, slave_port, master_ip, master_port))
        # elif key_spaces == len(current_masters):
        # replica migration should kick-in and balance it for us
        # https://redis.io/topics/cluster-spec#replica-migration
    elif not slaves_list or not masters_list:
        return _fail(ret, "Cluster replicate: both slaves_list and masters_list must be passed")
    else:
        # filter lists to use only available redis instances
        slaves_list = [s for s in slaves_list if s['name'] in nodes_ext.keys()]
        masters_list = [m for m in masters_list if m['name'] in nodes_ext.keys()]

        promote_ret = _promote(nodes_ext, masters_list)
        if not promote_ret['result']:
            return _fail(ret, "Cluster replicate, promotion of slaves has failed", [promote_ret['comment']])

        for slave in slaves_list:
            slave_ip, slave_port = _ip_port(nodes_ext, slave['name'], cidr)
            master_ip, master_port = _ip_port(nodes_ext, slave['of_master'], cidr)
            owned_slots = __salt__['redis_ext.slots'](slave_ip, slave_port)
            if not __salt__['redis_ext.delslots'](slave_ip, slave_port, owned_slots):
                return _fail(ret, "Unable to perform cluster replicate (previous slots deletion failed)")
            if not __salt__['redis_ext.replicate'](master_ip, master_port, slave_ip, slave_port):
                return _fail(ret, "Unable to perform cluster replicate (slave: {}:{}, master: {}:{})".format(slave_ip, slave_port, master_ip, master_port))
            ret['changes']["slave: {}:{}".format(slave_ip, slave_port)] = "master: {}:{}".format(master_ip, master_port)

    ret['result'] = True
    return ret


def reset(name, instances, cidr=None, hard=False):
    '''
    CLUSTER RESET given nodes
    If the node is the master node, FLUSHALL its keys

    :param name:
    :param instances:
    :param masters_names:
    :param cidr:
    :param hard:
    :return:
    '''
    ret = {'name': name,
           'result': False,
           'changes': {},
           'comment': ''}

    if not instances:
        log.info("No changes (cluster reset) will be made as required 'nodes' map is empty")
        ret['result'] = True
        return ret

    nodes_ext = copy.deepcopy(instances)
    try:
        nodes_ext = _cluster_state(nodes_ext, cidr)
    except RedisClusterConfigurationException as e:
        log.exception(e)
        return _fail(ret, "Cannot gather cluster-wide information")

    log.info("This operation will wipe following redis instances: {}".format(nodes_ext.keys()))

    for details in nodes_ext.values():
        ip = _filter_ip(details['ips'], cidr)[0]
        port = details['port']
        if details['master'] and not __salt__['redis_ext.flushall'](ip, port):
            return _fail(ret, "Unable to flush keys from {}:{}".format(ip, port))
        if not __salt__['redis_ext.reset'](ip, port, hard):
            return _fail(ret, "Unable to reset (hard: {}) instance {}:{}".format(hard, ip, port))
        ret['changes']["{}:{}".format(ip, port)] = "reset (hard: {})".format(hard)

    ret['result'] = True
    return ret
