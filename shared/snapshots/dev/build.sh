#!/bin/bash

. "$(readlink -nf ${BASH_SOURCE[0]%/*})/../functions.sh"

function build_snapshot_base() {
    sudo "$SCRIPT_BASE_DIR/base.sh" && cs snapshot create "$@"
}

function build_snapshot_home() {
    "$SCRIPT_BASE_DIR/home.sh" && cs snapshot create --home "$@"
}

build base/dev base
build home/dev home
