#!/usr/bin/env bash

source .travis/common.sh

docker_push "$DOCKER_USERNAME"/envoy:"$DOCKER_IMAGE-salt-minion"
docker_push "$DOCKER_USERNAME"/envoy:"$DOCKER_IMAGE-salt-master"
