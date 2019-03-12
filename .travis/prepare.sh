#!/usr/bin/env bash

source .travis/common.sh

docker_update

echo "===="
sudo cat /etc/docker/daemon.json

docker build \
    --build-arg=salt_ver=$SALT_VER \
    --target salt-minion \
    -t "$DOCKER_USERNAME/envoy-minion-$DOCKER_IMAGE:$TAG" \
    -f .travis/"$DOCKER_IMAGE"/Dockerfile .

docker build \
    --build-arg=salt_ver=$SALT_VER \
    --target salt-master \
    -t "$DOCKER_USERNAME/envoy-master-$DOCKER_IMAGE:$TAG" \
    -f .travis/"$DOCKER_IMAGE"/Dockerfile .

docker build \
    --build-arg=salt_ver=$SALT_VER \
    --target dry-test \
    -t "$DOCKER_USERNAME/envoy-dry-test-$DOCKER_IMAGE:$TAG" \
    -f .travis/"$DOCKER_IMAGE"/Dockerfile .

echo "BUILD:"
sudo ls -al $HOME/docker/