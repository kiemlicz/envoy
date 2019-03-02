#!/usr/bin/env bash

source .travis/common.sh

while sleep 9m; do echo "=====[ $SECONDS seconds still running ]====="; done &
# adding "-t" for test stdout
result=$(docker run -t --privileged "$DOCKER_USERNAME/envoy-dry-test-$DOCKER_IMAGE:$TAG")
kill %1
# in order to return proper exit code instead of always 0 (of kill command)
exit $result
