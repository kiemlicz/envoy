#!/usr/bin/env bash

touch /var/log/salt/minion
systemctl start salt-minion
tail -f /var/log/salt/minion &
python /opt/envoy_test.py
