#!/usr/bin/env bash

touch /var/log/salt/minion
service salt-minion start
tail -f /var/log/salt/minion &
python /opt/envoy_test.py
