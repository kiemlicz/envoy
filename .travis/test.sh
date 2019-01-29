#!/usr/bin/env bash

while sleep 9m; do echo "=====[ $SECONDS seconds still running ]====="; done &
docker run --privileged "$DOCKER_IMAGE-dry-test"
kill %1
