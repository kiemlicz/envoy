#!/usr/bin/env bash

source .travis/common.sh

while sleep 9m; do echo "=====[ $SECONDS seconds still running ]====="; done &
docker run --privileged "$DOCKER_USERNAME/envoy-dry-test-$DOCKER_IMAGE:$TAG"
kill %1
