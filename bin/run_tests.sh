#!/bin/bash

function in_docker(){
    test -f /.dockerenv
}

ROOT_DIR=$(realpath $(dirname "${BASH_SOURCE[0]}")/..)

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

function run_containers(){
    local RESULT
    local STARTED_DRIVER=false

    if ! docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | grep -q selenium-driver; then
        log "Starting driver"

        docker run -t -d --rm \
            --name selenium-driver \
            -p 4444:4444 \
            -p 7900:7900 \
            --shm-size=2g \
            seleniarm/standalone-firefox

        sleep 2

        STARTED_DRIVER=true
    fi

    log "Deleting old screenshots"

    rm -fr $ROOT_DIR/screenshots
    mkdir -p $ROOT_DIR/screenshots

    log "Running tests"

    docker run -it --rm \
        -v $ROOT_DIR/sites:/opt/paysauce-tests/sites \
        -v $ROOT_DIR/screenshots:/opt/paysauce-tests/screenshots \
        -v $ROOT_DIR/bin:/opt/paysauce-tests/bin \
        paysauce-tests $*

    RESULT=$?

    if $STARTED_DRIVER; then
        log "Stopping driver"

        docker stop selenium-driver
    fi

    return $RESULT
}

if ! in_docker; then
    run_containers $*
    exit $?
fi

while true; do
    case "$1" in
        --help|-h)
            echo "TODO: helptext"
            exit 0
            ;;
        *)
            break
            ;;
    esac
done

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
