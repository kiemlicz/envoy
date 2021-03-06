#!/usr/bin/env bash

source .travis/common.sh

docker_update

case "$1" in
dry)
    docker build \
        --build-arg=salt_ver=$SALT_VER \
        --target salt-minion \
        -t "envoy-minion-$DOCKER_IMAGE:$TAG" \
        -f .travis/"$DOCKER_IMAGE"/Dockerfile .

    docker build \
        --build-arg=salt_ver=$SALT_VER \
        --target salt-master \
        -t "envoy-master-$DOCKER_IMAGE:$TAG" \
        -f .travis/"$DOCKER_IMAGE"/Dockerfile .

    docker build \
        --build-arg=salt_ver=$SALT_VER \
        --target dry-test \
        -t "envoy-dry-test-$DOCKER_IMAGE:$TAG" \
        -f .travis/"$DOCKER_IMAGE"/Dockerfile .
    ;;
masterless)
    docker build \
        --build-arg=salt_ver=$SALT_VER \
        --build-arg=log_level="${LOG_LEVEL-info}" \
        --build-arg=saltenv="$SALTENV" \
        --target masterless-test \
        -t "masterless-test-$DOCKER_IMAGE:$TAG" \
        -f .travis/"$DOCKER_IMAGE"/Dockerfile .
    ;;
esac
