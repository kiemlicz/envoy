#!/usr/bin/env bash

#rsync
rsync -av --delete -e ssh {{ locations }} {{ remote }}:{{ destination }}
#archive
name={{ archive }}.$(date +%Y%m%d.%H%M.tgz)
archive_cmd="tar cvfz $name {{ destination }}"
ssh {{ remote }} "$archive_cmd"
