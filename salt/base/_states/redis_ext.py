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


def _reset_and_meet(name, nodes, cidr, hard):
    reset_ret = __states__['redis_ext.reset']("{}_reset".format(name), nodes, cidr, hard=hard)
    if not reset_ret['result']:
        return reset_ret
    # meet again, because of reset
    meet_ret = __states__['redis_ext.met']("{}_meet".format(name), nodes, cidr)
    return meet_ret


def _cluster_state(nodes, cidr, include_slots=True):
    '''
    Enrich input nodes map with cluster nodes and cluster slots commands
    :param nodes:
    :param cidr:
    :return:
    '''
    for name, details in nodes.items():
        ip = _filter_ip(details['ips'], cidr)[0]
        port = details['port']
        node_view = __salt__['redis_ext.nodes'](ip, port)
        if not node_view:
            msg = "Redis instance {}:{} doesn't contain 'myself' in its cluster nodes".format(ip, port)
            log.error(msg)
            raise RedisClusterConfigurationException(msg)

        for ip_port, node_details in node_view.items():
            if 'fail' in node_details['flags']:
                msg = "Cluster view as seen from {}:{} contains 'fail' flag for {}".format(ip,port, ip_port)
                log.error(msg)
                raise RedisClusterConfigurationException(msg)
            elif 'myself' in node_details['flags']:
                details['master'] = True if 'master' in node_details['flags'] else False
                if not details['master']:
                    details['master_id'] = node_details['master_id']

        if include_slots:
            details['current_slots'] = __salt__['redis_ext.slots'](ip, port)

    return nodes


def _has_any_slots(nodes):
    for details in nodes.values():
        if details['current_slots']:
            return True
    return False


def _ip_port(nodes, name, cidr):
    return _filter_ip(nodes[name]['ips'], cidr)[0], nodes[name]['port']


#deprecated, not needed
def managed(name, nodes, min_nodes, desired_masters, replication_factor = 2, desired_slots=None, cidr=None, policy="split"):
    '''
    Ensures redis is running with all cluster parameters (master:slave ratio, slots assignment, replicas)

    :param min_nodes: minimum number of already instantiated nodes before starting the slots assignment
    :param nodes: { 'hostname1': {'ips': ["127.0.0.1"], 'port': 6379 }} all currently available nodes
    :param desired_masters:
    :param total_slots:
    :param desired_slots: {'hostname1': [1,2,3,4]}
    :param cidr: 192.168.1.0/24 multiple addresses optional filter
    :param policy: slots assignment strategy (one_by_one or split)
    :return:
    '''

    ret = {'name': name,
           'result': False,
           'changes': {},
           'comment': ''}

    if not nodes:
        log.info("No changes (cluster slots management) will be made as required 'nodes' are empty")
        ret['result'] = True
        return ret
    elif len(nodes) < min_nodes:  # todo reconsider usage as simple jinja filter could suffice
        return _fail(ret, "Insufficient number of running redis instances, required: {}, found: {}".format(min_nodes, len(nodes)))

    # filter masters/slaves to include only those available in this run
    desired_masters = [e for e in desired_masters if e in nodes.keys()]

    nodes_ext = copy.deepcopy(nodes)
    nodes_ext = _cluster_state(nodes_ext, cidr)  # not needed potentially

    if not nodes_ext:
        return _fail(ret, "Unable to configure redis cluster as one node contains improper configuration")

    log.debug("Current cluster state: {}".format(nodes_ext))
    log.debug("Desired slots assignment: {}".format(desired_slots))

    # fixme - most likely completing replicated state will take over this state
    # in sls just use below (else's) steps
    if _has_any_slots(nodes_ext):
        pass # fixme
    else:
        # there are no slots assigned but the roles were not checked and could have been assigned
        reset_meet_ret = _reset_and_meet(name, nodes, cidr, hard=False)
        if not reset_meet_ret['result']:
            return _fail(ret, "Cluster reset and meet has failed", [reset_meet_ret['comment']])
        # read instances pillar, if not found use replication_factor
        replicate_ret = __states__['redis_ext.replicated']("{}_replicated".format(name), ???)
        if not replicate_ret['result']:
            return _fail(ret, "Cluster replicate has failed", [replicate_ret['comment']])
        # read instances pillar, if not found use replication_factor
        # fixme - I think it is not needed if we do balancing in replicate
        balance_ret = __states__['redis_ext.balanced']("{}_balanced".format(name), ???)
        if not balance_ret['result']:
            return _fail(ret, "Cluster balancing has failed", [balance_ret['comment']])


    promote_ret = roles(name, nodes, desired_masters, cidr=cidr)
    if not promote_ret['result']:
        ret['comment'] = "delegated redis_ext.promote has failed"
        ret['changes'] = promote_ret['changes']
        return ret

    ret['result'] = True
    return ret


def met(name, nodes, cidr=None):
    '''
    Redis CLUSTER MEETs all instances
    This state run results in all instances connected to others (given proper network configuration etc.)

    :param name:
    :param nodes: All currently available redis instances: { 'hostname1': {'ips': ["127.0.0.1", "1.2.3.4"], 'port': 6379 }}
    :param cidr: network with mask to filter out ip addresses from 'ips' list
    :param fail_if_empty_nodes: fail state if nodes is empty
    '''
    ret = {'name': name,
           'result': False,
           'changes': {},
           'comment': ''}

    if not nodes:
        log.info("No changes (cluster meet), required 'nodes' map is empty")
        ret['result'] = True
        return ret

    initiator_ip, initiator_port = _ip_port(nodes, nodes.keys()[0], cidr)
    others = [[_filter_ip(v['ips'], cidr)[0], v['port']] for k, v in nodes.items()]

    log.info("Cluster meet from {}:{} to: {}".format(initiator_ip, initiator_port, others))

    if __salt__['redis_ext.meet'](initiator_ip, initiator_port, others):
        ret['result'] = True
        ret['changes']["{}:{}".format(initiator_ip, initiator_port)] = "met: {}".format(others)
        return ret
    else:
        return _fail(ret, "Unable to perform cluster meet")


def balanced(name, nodes, desired_masters, desired_slots=None, total_slots=16384, cidr=None, policy="split"):
    '''
    For current number of masters balances the cluster

    :param name:
    :param nodes:
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

    if not nodes:
        log.info("No changes (cluster balance) will be made as required 'nodes' map is empty")
        ret['result'] = True
        return ret

    nodes_ext = copy.deepcopy(nodes)
    try:
        nodes_ext = _cluster_state(nodes_ext, cidr)
    except RedisClusterConfigurationException as e:
        log.exception(e)
        return _fail(ret, "Cluster balancing: cannot gather cluster-wide information")

    actions = {}

    if desired_masters is None:
        log.info("Cluster balancing: using current's view masters")
        desired_masters = [m for m, v in nodes_ext.items() if v['master']]

    if desired_slots is None:
        desired_slots = {}
        # todo add consistent hashing

        # sort desired masters lexicographically to avoid redundant migration
        desired_masters = desired_masters.sort(key=lambda m: m['name'])

        def split():
            '''
            Splits the slots range in consecutive, continuous ranges
            '''
            s, r = divmod(total_slots, len(desired_masters))
            start = 0
            for master in desired_masters:
                end = start + s if start + s + r < total_slots else start + s + r
                for i in range(start, end):
                    desired_slots.setdefault(master, []).append(i)
                start = end
            return desired_slots

        def one_by_one():
            '''
            Splits the slots range in discontinuous sets e.g. node1: [0,2,4,6]; nodes2: [1,3,5,7]
            '''
            for i in xrange(total_slots):
                desired_slots.setdefault(desired_masters[i % len(desired_masters)], []).append(i)
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

    log.info("Cluster balancing: actions: {}".format(actions))

    for desired_master, action_map in actions.items():
        dest_ip, dest_port = _ip_port(nodes_ext, desired_master, cidr)
        changes_key = "destination node: {}".format(desired_master)

        # this is safe action, slots are not assigned anywhere else
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

    return ret


def replicated(name, nodes, slaves_list=None, masters_list=None, replication_factor=2, cidr=None):
    '''
    CLUSTER REPLICATE either using by name slaves_list list or if the list is None, using replication_factor
    Assumes that the data will be split among all passed master nodes.
    The number of slot spaces will be equal to: `len(nodes)/replication_factor`

    :param name:
    :param nodes:
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

    if not nodes:
        log.info("No changes (cluster replicate) will be made as required 'nodes' map is empty")
        ret['result'] = True
        return ret

    if (slaves_list is None and masters_list is None) and len(nodes) < replication_factor:
        return _fail(ret, "Cluster replicate: insufficient number of redis instances ({}) for replication factor = {}".format(len(nodes), replication_factor))

    nodes_ext = copy.deepcopy(nodes)
    try:
        nodes_ext = _cluster_state(nodes_ext, cidr)
    except RedisClusterConfigurationException as e:
        log.exception(e)
        return _fail(ret, "Cluster replicate: cannot gather cluster-wide information")

    def _promote(nodes_ext, desired_masters):
        # reset roles of current slaves that must become masters
        upgrade = {}
        for current_slave in [m for m in desired_masters if not nodes_ext[m['name']]['master']]:
            upgrade[current_slave] = nodes_ext[current_slave]

        return _reset_and_meet(name, upgrade, cidr, hard=False)

    if slaves_list is None and masters_list is None:
        all_nodes = nodes_ext.keys()
        key_spaces = len(all_nodes) / replication_factor
        current_masters = [{'name': m} for m,v in nodes_ext.items() if v['master']]
        current_slaves = [{'name': s} for s,v in nodes_ext.items() if not v['master']]

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
            balanced_ret = __states__['redis_ext.balanced'](name, nodes, desired_masters, cidr=cidr)
            if not balanced_ret['result']:
                return _fail(ret, "Cluster replicate: unable to balance slots among: {}".format(desired_masters), [balanced_ret['comment']])
            for new_slave in extra_masters:
                slave_ip, slave_port = _ip_port(nodes_ext, new_slave['name'], cidr)
                # replica migration will balance this poor choice
                master_ip, master_port = _ip_port(nodes_ext, desired_masters[0]['name'], cidr)
                if not __salt__['redis_ext.replicate'](master_ip, master_port, slave_ip, slave_port):
                    return _fail(ret, "Cluster replicate: slave ({}:{}) cannot replicate master ({}:{})".format(slave_ip, slave_port, master_ip, master_port))
        # elif key_spaces == len(current_masters):
        # replica migration should kick-in and balance it for us
        # https://redis.io/topics/cluster-spec#replica-migration
    elif slaves_list is None or masters_list is None:
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


def reset(name, nodes, cidr=None, hard=False):
    '''
    CLUSTER RESET given nodes
    If the node is the master node, FLUSHALL its keys

    :param name:
    :param nodes:
    :param masters_names:
    :param cidr:
    :param hard:
    :return:
    '''
    ret = {'name': name,
           'result': False,
           'changes': {},
           'comment': ''}

    if not nodes:
        log.info("No changes (cluster reset) will be made as required 'nodes' map is empty")
        ret['result'] = True
        return ret

    nodes_ext = copy.deepcopy(nodes)
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
