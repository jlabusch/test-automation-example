#!/bin/bash

function in_docker(){
    test -f /.dockerenv
}

ROOT_DIR=$(realpath $(dirname "${BASH_SOURCE[0]}")/..)
ONLY_DRIVER=false

function log(){
    local fatal=false

    while true; do
        case "$1" in
            --fatal)
                fatal=true
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    echo "$*" >&2

    if $fatal; then
        exit 1
    fi
}

function get_local_ip(){
    ifconfig | grep inet | grep -v inet6 | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1
}

function run_containers(){
    local RESULT
    local STARTED_DRIVER=false
    local ONLY_DRIVER=false

    while true; do
        case "$1" in
            --only-driver)
                ONLY_DRIVER=true
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    if ! docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | grep -q selenium-driver; then
        log "Starting driver"

        docker run -t -d --rm \
            --name selenium-driver \
            -p 4444:4444 \
            -p 7900:7900 \
            --shm-size=2g \
            seleniarm/standalone-firefox

        RESULT=$?

        STARTED_DRIVER=true

        sleep 2
    fi

    if ! $ONLY_DRIVER; then
        log "Deleting old screenshots"

        rm -fr $ROOT_DIR/screenshots
        mkdir -p $ROOT_DIR/screenshots

        log "Running tests"

        docker run -it --rm \
            -v $ROOT_DIR/sites:/opt/paysauce-tests/sites \
            -v $ROOT_DIR/screenshots:/opt/paysauce-tests/screenshots \
            -v $ROOT_DIR/bin:/opt/paysauce-tests/bin \
            -e SELENIUM_HUB_HOST=$(get_local_ip) \
            paysauce-tests $*

        RESULT=$?

        if $STARTED_DRIVER; then
            log "Stopping driver"

            docker stop selenium-driver
        fi
    fi

    return $RESULT
}

while true; do
    case "$1" in
        --help|-h)
            echo "Usage:   ./bin/run_tests.sh [test-dir]"
            echo "Example: ./bin/run_tests.sh www.paysauce.com"
            exit 0
            ;;
        *)
            break
            ;;
    esac
done

if ! in_docker; then
    run_containers $*
    exit $?
fi

function run_tests_for(){
    local DIR="$1"

    log "Testing $DIR"

    if [ ! -d "$DIR" ]; then
        if [ -d "./sites/$DIR" ]; then
            DIR="./sites/$DIR"
        else
            log --fatal "No such directory: $DIR"
        fi
    fi

    pushd $DIR >/dev/null 2>&1
    npx cucumber-js
    popd >/dev/null 2>&1
}

mkdir -p screenshots

for DIR in $*; do
    run_tests_for $DIR
done
