#!/usr/bin/env bash

source .travis/common.sh

docker_push "$DOCKER_USERNAME/envoy-minion-$DOCKER_IMAGE:$TAG"
docker_push "$DOCKER_USERNAME/envoy-master-$DOCKER_IMAGE:$TAG"
