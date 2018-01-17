
mongodb_initiate_replica_set:
  cmd.run:
    - name: mongo --host {{ bind.host }} --port {{ bind.port }} --eval 'rs.initiate({ _id: {{ bind.replica_name }}, members: {{ bind.memebers }} })'
