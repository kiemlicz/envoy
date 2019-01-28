#!/usr/bin/env bash

source .travis/common.sh

docker_update

docker build \
    --build-arg=salt_ver=$SALT_VER \
    --target salt-minion \
    -t kiemlicz/envoy:"$DOCKER_IMAGE-salt-minion" \
    -f .travis/"$DOCKER_IMAGE"/Dockerfile .

docker build \
    --build-arg=salt_ver=$SALT_VER \
    --target salt-master \
    -t kiemlicz/envoy:"$DOCKER_IMAGE-salt-master" \
    -f .travis/"$DOCKER_IMAGE"/Dockerfile .

docker build \
    --build-arg=salt_ver=$SALT_VER \
    --target dry-test \
    -t kiemlicz/envoy:"$DOCKER_IMAGE-dry-test" \
    -f .travis/"$DOCKER_IMAGE"/Dockerfile .
