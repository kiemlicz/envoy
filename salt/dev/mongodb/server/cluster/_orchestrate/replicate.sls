#!py

import json

# according to https://docs.mongodb.com/manual/tutorial/deploy-replica-set/
# this state must execute on one minion only
# this state run on existing replica will reconfigure it
def run():
  mongodb = __pillar__["mongodb"]
  master = mongodb["master"]
  state = {}
  members = []

  for i in xrange(0, len(mongodb['replicas'])):
    replica = mongodb['replicas'][i]
    members.append({
      '_id': i,
      'host': "{}:{}".format(replica['ip'], replica['port'])
    })

  replica_config = json.dumps({
    '_id': master['replica_name'],
    'members': members
  })

  state['mongodb_initiate_replica_set'] = {
    'cmd.run': [
      { 'name': "mongo --host {} --port {} --eval 'rs.initiate({})'".format(master['ip'], master['port'], replica_config) },
      { 'onlyif': "mongo --host {} --port {} --eval 'rs.status()' | grep 'errmsg'".format(master['ip'], master['port']) }
    ]
  }

  state['mongodb_reconfig_replica_set'] = {
    'cmd.run': [
      { 'name': "mongo --host {} --port {} --eval 'rs.reconfig({})'".format(master['ip'], master['port'], replica_config) },
      { 'unless': "mongo --host {} --port {} --eval 'rs.status()' | grep 'errmsg'".format(master['ip'], master['port']) }
    ]
  }

  return state
