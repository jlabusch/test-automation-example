#!/bin/bash

function fatal_error(){
    echo "$*" >&2
    exit 1
}

function install_chrome(){
    local base_url="http://chromedriver.storage.googleapis.com"
    local file="chromedriver_linux64.zip"
    local version=$(curl -s "$base_url/LATEST_RELEASE")
    local dir=$(mktemp -d)

    test $? -eq 0 || fatal_error "Failed to determine Chrome webdriver version"

    pushd $dir || fatal_error "$dir does not exist"

    curl -s -O "$base_url/$version/$file" || fatal_error "Failed to download Chrome webdriver"

    unzip $file || fatal_error "Failed to extract $file"

    install -m 755 chromedriver /usr/bin/ || fatal_error "Failed to install Chrome webdriver"

    popd

    rm -fr $dir
}

install_chrome
