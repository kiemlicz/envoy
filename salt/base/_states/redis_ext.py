import logging
import time
import copy
from salt.exceptions import SaltException


log = logging.getLogger(__name__)


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


def _filter_ip(ips, cidr=None):
    if cidr:
        return [e for e in ips if __salt__['network.ip_in_subnet'](e, cidr)]
    else:
        return ips


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

    initiator = nodes[nodes.keys()[0]]
    initiator_ip = _filter_ip(initiator['ips'], cidr)[0]
    initiator_port = initiator['port']
    others = [[_filter_ip(v['ips'], cidr)[0], v['port']] for k, v in nodes.items()]

    log.info("Cluster meet from {}:{} to: {}".format(initiator_ip, initiator_port, others))

    if __salt__['redis_ext.meet'](initiator_ip, initiator_port, others):
        ret['result'] = True
        ret['changes']["{}:{}".format(initiator_ip, initiator_port)] = "met: {}".format(others)
        return ret
    else:
        return _fail(ret, "Unable to perform cluster meet")


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

    if _has_any_slots(nodes_ext):
        pass # fixme
    else:
        reset_ret = __states__['redis_ext.reset']("{}_initial_reset".format(name), nodes, cidr, hard=False)
        if not reset_ret['result']:
            return _fail(ret, "Initial cluster reset has failed", [reset_ret['comment']])
        meet_ret = __states__['redis_ext.met']("{}_meet_after_reset".format(name), nodes, cidr)
        if not meet_ret['result']:
            return _fail(ret, "Cluster meet after cluster reset has failed", [meet_ret['comment']])
        # read instances pillar, if not found use replication_factor
        replicate_ret = __states__['redis_ext.replicated']("{}_replicated".format(name), ???)
        if not replicate_ret['result']:
            return _fail(ret, "Cluster replicate has failed", [replicate_ret['comment']])
        # read instances pillar, if not found use replication_factor
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


def balanced(name, nodes, desired_slots=None, total_slots=16384, cidr=None, policy="split"):
    '''
    For current number of masters balances the cluster

    :param name:
    :param nodes:
    :param desired_masters:
    :param desired_slots:
    :param total_slots:
    :param cidr:
    :param policy:
    :return:
    '''
    ret = {'name': name,
           'result': False,
           'changes': {},
           'comment': ''}

    nodes_ext = copy.deepcopy(nodes)
    nodes_ext = _cluster_state(nodes_ext, cidr)
    actions = {}

    if not nodes_ext:
        log.error("Unable to configure redis cluster as one node contains improper configuration")
        ret['comment'] = "Unable to configure redis cluster as one node contains improper configuration"
        return ret

    if desired_slots is None:
        desired_slots = {}

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

    for node_name, desired_slot_list in desired_slots.items():
        add = set(desired_slot_list) - set(nodes_ext[node_name]['current_slots'])
        migrate_map = {}
        for other_node in [e for e in nodes_ext.keys() if e != node_name and nodes_ext[e]['master']]:
            to_migrate = set(nodes_ext[other_node]['current_slots']) & set(add)
            if len(to_migrate) != 0:
                migrate_map[other_node] = to_migrate
                add = add - to_migrate
        actions[node_name] = {
            'add': add,
            'migrate': migrate_map
        }

    log.info("Computed actions: {}".format(actions))

    for node_name, action_map in actions.items():
        dest_ip = _filter_ip(nodes_ext[node_name]['ips'], cidr)[0]
        dest_port = nodes_ext[node_name]['port']
        changes_key = "destination node: {}".format(node_name)

        if __salt__['redis_ext.addslots'](dest_ip, dest_port, action_map['add']):
            log.debug("Added slots to {}:{}".format(dest_ip, dest_port))
            ret['changes'][changes_key] = {
                'slots added': action_map['add']
            }
        else:
            log.error("Unable to add slots to: {}:{}".format(dest_ip, dest_port))
            ret['changes'][changes_key] = {
                'slots added': "Failed. Wanted to add: {}".format(action_map['add'])
            }
            return ret

        for source_name, to_migrate in action_map['migrate'].items():
            src_ip = _filter_ip(nodes_ext[source_name]['ips'], cidr)[0]
            src_port = nodes_ext[source_name]['port']
            result = __salt__['redis_ext.migrate'](src_ip, src_port, dest_ip, dest_port, to_migrate)
            log.debug("Migrating slots from {}:{} to {}:{}".format(src_ip, src_port, dest_ip, dest_port))
            ret['changes'][changes_key].update({"slots migrated to this node": result})
            if not result['result']:
                log.error("Failed to migrate slots ({}:{} -> {}:{})".format(src_ip, src_port, dest_ip, dest_port))
                ret['changes'][changes_key].update({"slots migrated to this node": result})
                return ret

    return ret


def roles(name, nodes, desired_masters, attempts=4, cidr=None):
    ret = {'name': name,
           'result': False,
           'changes': {},
           'comment': ''}

    # failover will not be able to change the number of master nodes

    if not nodes:
        log.info("No changes (cluster promote slaves to masters) will be made as required names are empty")
        ret['result'] = True
        return ret

    # filter masters/slaves to include only those available in this run
    desired_masters = [e for e in desired_masters if e in nodes.keys()]

    nodes_ext = copy.deepcopy(nodes)
    nodes_ext = _cluster_state(nodes_ext, cidr, include_slots=False)

    if not nodes_ext:
        msg = "Unable to configure redis cluster as one node contains improper configuration"
        log.error(msg)
        ret['comment'] = msg
        return ret

    def _converged(nodes_ext):
        current_masters = [e for e in nodes_ext.keys() if nodes_ext[e]['master']]
        log.warn("current: {} desirec {}, all: {}".format(current_masters, desired_masters, nodes_ext.keys()))
        return set(current_masters) == set(desired_masters)

    def _failover(attempts, nodes_ext):
        if attempts <= 0:
            log.error("Cannot swap slave <-> master roles")
            return {}
        elif not nodes_ext:
            log.error("Cluster failover has failed during operation")
            return {}
        elif _converged(nodes_ext):
            log.debug("Failover completed successfully")
            return nodes_ext
        else:
            for current_slave in [m for m in desired_masters if not nodes_ext[m]['master']]:
                slave_ip = _filter_ip(nodes_ext[current_slave]['ips'], cidr)[0]
                slave_port = nodes_ext[current_slave]['port']
                log.warn("{}:{} failover".format(slave_ip, slave_port))
                if not __salt__['redis_ext.failover'](slave_ip, slave_port):
                    msg = "Unable to promote: {}:{} to master".format(slave_ip, slave_port)
                    ret['changes']["instance {}:{}".format(slave_ip, slave_port)] = "failed to upgrade to master"
                    log.error(msg)
                    return {}

            time.sleep(5)  # wait for cluster, todo schedule some other state for later execution instead of sleep
            return _failover(attempts - 1, _cluster_state(nodes_ext, cidr, include_slots=False))

    log.warn("START = {}".format(nodes_ext.keys()))

    if not _failover(attempts, nodes_ext):
        ret['comment'] = "Unable to promote some slaves to masters"
        return ret

    ret['result'] = True
    return ret


def replicated(name, nodes, keys=None, slaves_list=None, masters_list=None, replication_factor=2, cidr=None):
    '''
    CLUSTER REPLICATE either using by name slaves_list list or if the list is empty, using replication_factor
    Assumes that the data will be split among all passed nodes

    :param name:
    :param nodes:
    :param keys: number of key spaces (desired number of
    :param slaves_list: [{'name': 'name1', 'of_master': 'name2'},]
    :param masters_list:
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

    nodes_ext = copy.deepcopy(nodes)
    try:
        nodes_ext = _cluster_state(nodes_ext, cidr)
    except RedisClusterConfigurationException as e:
        log.exception(e)
        return _fail(ret, "Cannot gather cluster-wide information")

    # fixme validation of either factor or list nodes availability

    if slaves_list is None and masters_list is None:
        all_nodes = nodes_ext.keys()
        # read master and slave nodes, check ratio
        # reset roles
        # replicate and done
    else:
        # reset roles for slaves that must become masters
        upgrade = {}
        for current_slave in [m for m in masters_list if not nodes_ext[m]['master']]:
            upgrade[current_slave] = nodes_ext[current_slave]
        #reset and meet upgrade nodes
        for slave in [e for e in slaves_list if e['name'] in nodes_ext.keys()]:
            slave_ip = _filter_ip(nodes_ext[slave['name']]['ips'], cidr)[0]
            slave_port = nodes_ext[slave['name']]['port']
            master_ip = _filter_ip(nodes_ext[slave['of_master']]['ips'], cidr)[0]
            master_port = nodes_ext[slave['of_master']]['port']
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

class RedisClusterConfigurationException(SaltException):
    pass
