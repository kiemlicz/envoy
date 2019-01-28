#!/usr/bin/env bash

source .travis/common.sh

docker_push kiemlicz/envoy:"$DOCKER_IMAGE-salt-minion"
docker_push kiemlicz/envoy:"$DOCKER_IMAGE-salt-master"
