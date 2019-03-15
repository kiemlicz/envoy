#!/usr/bin/env bash

source .travis/common.sh

case "$1" in
dry)
    while sleep 9m; do echo "=====[ $SECONDS seconds still running ]====="; done &
    docker run --privileged "envoy-dry-test-$DOCKER_IMAGE:$TAG"
    result=$?
    kill %1
    # in order to return proper exit code instead of always 0 (of kill command)
    exit $result
    ;;
masterless)
    # privileged mode is necessary for e.g. setting: net.ipv4.ip_forward or running docker in docker
    name="ambassador-salt-masterless-run-$TRAVIS_JOB_NUMBER"
    while sleep 9m; do echo "=====[ $SECONDS seconds still running ]====="; done &
    docker run --name $name --hostname "$CONTEXT-host" --privileged "masterless-test-$DOCKER_IMAGE:$TAG" 2>&1 | tee output
    exit_code=$?
    kill %1
    if [[ "$exit_code" != 0 ]]; then
        echo "found failures"
        exit $exit_code
    fi
    result=$(awk '/^Failed:/ {if($2 != "0") print "fail"}' output)
    if [[ "$result" == "fail" ]]; then
        echo "found failures"
        exit 3
    fi
    ;;
esac

