#!/usr/bin/env bash

salt-run saltutil.sync_all
/usr/bin/supervisord
