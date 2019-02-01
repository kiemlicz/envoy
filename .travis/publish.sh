#!/usr/bin/env bash

source .travis/common.sh

docker_push "$DOCKER_USERNAME/envoy/minion/$DOCKER_IMAGE:$ENVOY_TAG"
docker_push "$DOCKER_USERNAME/envoy/master/$DOCKER_IMAGE:$ENVOY_TAG"
