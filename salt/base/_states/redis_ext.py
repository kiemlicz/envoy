import logging


def _filter_ip(ips, cidr=None):
    if cidr:
        return [e for e in ips if __salt__['network.ip_in_subnet'](e, cidr)]
    else:
        return ips


def meet(name, nodes_map, cidr=None):
    ret = {'name': name,
           'result': False,
           'changes': {},
           'comment': ''}
    log = logging.getLogger(__name__)

    if not nodes_map:
        log.info("No changes (cluster meet) will be made as required nodes_map is empty")
        ret['result'] = True
        return ret

    initiator = nodes_map[nodes_map.keys()[0]]
    initiator_ip = _filter_ip(initiator['ips'], cidr)[0]
    initiator_port = initiator['port']
    others = [[_filter_ip(v['ips'], cidr)[0], v['port']] for k, v in nodes_map.items()]

    log.info("Cluster meet from {}:{} to: {}".format(initiator_ip, initiator_port, others))

    if __salt__['redis_ext.meet'](initiator_ip, initiator_port, others):
        ret['result'] = True
        ret['changes']["node: {}:{}".format(initiator_ip, initiator_port)] = "met: {}".format(others)
        return ret
    else:
        log.error("Unable to perform cluster meet")
        return ret


def replicate(name, nodes_map, slaves_list, cidr=None):
    ret = {'name': name,
           'result': False,
           'changes': {},
           'comment': ''}
    log = logging.getLogger(__name__)

    if not nodes_map:
        log.info("No changes (cluster replicate) will be made as required nodes_map is empty")
        ret['result'] = True
        return ret

    for slave in [e for e in slaves_list if e['name'] in nodes_map.keys()]:
        slave_ip = _filter_ip(nodes_map[slave['name']]['ips'], cidr)[0]
        slave_port = nodes_map[slave['name']]['port']
        master_ip = _filter_ip(nodes_map[slave['of_master']]['ips'], cidr)[0]
        master_port = nodes_map[slave['of_master']]['port']
        owned_slots = __salt__['redis_ext.slots'](slave_ip, slave_port)
        if not __salt__['redis_ext.delslots'](slave_ip, slave_port, owned_slots):
            log.error("Unable to perform cluster replicate (previous slots deletion failed)")
            return ret
        if not __salt__['redis_ext.replicate'](master_ip, master_port, slave_ip, slave_port):
            log.error("Unable to perform cluster replicate (slave: {}:{}, master: {}:{})".format(slave_ip, slave_port, master_ip, master_port))
            return ret
        else:
            ret['changes']["slave: {}:{}".format(slave_ip, slave_port)] = "master: {}:{}".format(master_ip, master_port)
    ret['result'] = True
    return ret


def managed(name, nodes_map, min_nodes, master_names, total_slots=16384, desired_slots=None, cidr=None, strat="split"):
    '''
    :param min_nodes: minimum number of already instantiated nodes before starting the slots assignment
    :param name: migrating node (hostname or pod name)
    :param nodes_map: { 'hostname1': {'ips': ["127.0.0.1"], 'port': 6379 }}
    :param master_names:
    :param total_slots:
    :param desired_slots: {'hostname1': [1,2,3,4]}
    :param cidr: 192.168.1.0/24 mutliple addresses optional filter
    :param strat: slots assignment strategy (one_by_one or split)
    :return:
    '''

    ret = {'name': name,
           'result': False,
           'changes': {},
           'comment': ''}
    log = logging.getLogger(__name__)

    if not nodes_map:
        log.info("No changes (cluster slots management) will be made as required nodes_map is empty")
        ret['result'] = True
        return ret
    elif len(nodes_map) < min_nodes:
        log.info("No changes will be made as required: {} desired hosts, but found: {}".format(len(desired_slots), len(nodes_map)))
        ret['result'] = True
        return ret
    # filter masters to include only those available in this run
    master_names = [e for e in master_names if e in nodes_map.keys()]

    if desired_slots is None:
        desired_slots = {}

        def split():
            '''
            Splits the slots range in consecutive, continuous ranges
            '''
            s, r = divmod(total_slots, len(master_names))
            start = 0
            for master in master_names:
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
                desired_slots.setdefault(master_names[i % len(master_names)], []).append(i)
            return desired_slots

        policies = {
            'split': split(),
            'one_by_one': one_by_one()
        }
        policies[strat]()

    assigned_slots = {}
    actions = {}
    for name, details in nodes_map.items():
        ip = _filter_ip(details['ips'], cidr)[0]
        port = details['port']
        log.debug("Finding current slot assignmet for {}:{} (name: {})".format(ip, port, name))
        assigned_slots[name] = __salt__['redis_ext.slots'](ip, port)

    log.info("Current slots assignment: {}".format(assigned_slots))
    log.info("Desired slots assignment: {}".format(desired_slots))

    # fixme failover

    for node_name, desired_slot_list in desired_slots.items():
        add = set(desired_slot_list) - set(assigned_slots[node_name])
        migrate_map = {}
        for other_node in [e for e in assigned_slots.keys() if e != node_name]:
            to_migrate = set(assigned_slots[other_node]) & set(add)
            if len(to_migrate) != 0:
                migrate_map[other_node] = to_migrate
                add = add - to_migrate
        actions[node_name] = {
            'add': add,
            'migrate': migrate_map
        }

    log.info("Computed actions: {}".format(actions))

    for node_name, action_map in actions.items():
        dest_ip = _filter_ip(nodes_map[node_name]['ips'], cidr)[0]
        dest_port = nodes_map[node_name]['port']
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
            src_ip = _filter_ip(nodes_map[source_name]['ips'], cidr)[0]
            src_port = nodes_map[source_name]['port']
            result = __salt__['redis_ext.migrate'](src_ip, src_port, dest_ip, dest_port, to_migrate)
            log.debug("Migrating slots from {}:{} to {}:{}".format(src_ip, src_port, dest_ip, dest_port))
            ret['changes'][changes_key].update({"slots migrated to this node": result})
            if not result['result']:
                log.error("Failed to migrate slots ({}:{} -> {}:{})".format(src_ip, src_port, dest_ip, dest_port))
                ret['changes'][changes_key].update({"slots migrated to this node": result})
                return ret

    ret['result'] = True
    return ret


def reset(name, nodes_map, masters_names, cidr=None):
    ret = {'name': name,
           'result': False,
           'changes': {},
           'comment': ''}
    log = logging.getLogger(__name__)

    log.info("This operation will wipe all redis instances: {}".format(nodes_map))

    for name, details in nodes_map.items():
        ip = _filter_ip(details['ips'], cidr)[0]
        port = details['port']
        if name in masters_names and not __salt__['redis_ext.flushall'](ip, port):
            log.error("Unable to flush keys from {}:{}".format(ip, port))
            return ret
        if not __salt__['redis_ext.reset'](ip, port):
            log.error("Unable to reset instance {}:{}".format(ip, port))
            return ret
        ret['changes']["instance {}:{}".format(ip, port)] = "reset"

    ret['result'] = True
    return ret
